import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/network/create_dio.dart';
import 'package:app/core/network/token_provider.dart';

import 'fake_http_adapter.dart';

/// Token palsu: setiap `forceRefresh` menghasilkan token baru (`token-1`, `token-2`, ...).
class FakeTokenProvider implements TokenProvider {
  FakeTokenProvider({this.loggedIn = true});

  bool loggedIn;
  int _version = 1;
  int refreshCount = 0;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    if (!loggedIn) return null;
    if (forceRefresh) {
      refreshCount++;
      _version++;
    }
    return 'token-$_version';
  }
}

void main() {
  late FakeTokenProvider tokens;

  Dio dioWith(FakeHttpAdapter adapter) =>
      createDio(baseUrl: 'http://api.test', tokens: tokens)
        ..httpClientAdapter = adapter;

  String? authHeader(RequestOptions options) =>
      options.headers['Authorization'] as String?;

  setUp(() => tokens = FakeTokenProvider());

  test('menambahkan ID token terbaru ke header Authorization', () async {
    final adapter = FakeHttpAdapter((_) => jsonResponse({'ok': true}, 200));

    await dioWith(adapter).get<Object?>('/v1/me');

    expect(authHeader(adapter.requests.single), 'Bearer token-1');
    expect(tokens.refreshCount, 0);
  });

  test(
    'tanpa user login, request dikirim tanpa header Authorization',
    () async {
      tokens.loggedIn = false;
      final adapter = FakeHttpAdapter((_) => jsonResponse({'ok': true}, 200));

      await dioWith(adapter).get<Object?>('/health');

      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    },
  );

  test(
    '401 → token di-refresh sekali, request diulang dengan token baru',
    () async {
      final adapter = FakeHttpAdapter(
        (options) => authHeader(options) == 'Bearer token-2'
            ? jsonResponse({'id': 'u1'}, 200)
            : jsonResponse(errorBody('UNAUTHENTICATED'), 401),
      );

      final response = await dioWith(adapter)
          .get<Map<String, Object?>>('/v1/me');

      expect(response.statusCode, 200);
      expect(response.data, {'id': 'u1'});
      expect(tokens.refreshCount, 1);
      expect(adapter.requests.map(authHeader), [
        'Bearer token-1',
        'Bearer token-2',
      ]);
    },
  );

  test(
    '401 lagi setelah refresh → tidak refresh kedua kali, error 401 diteruskan',
    () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse(errorBody('UNAUTHENTICATED'), 401),
      );

      final call = dioWith(adapter).get<Object?>('/v1/me');

      await expectLater(
        call,
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      expect(tokens.refreshCount, 1);
      expect(adapter.requests, hasLength(2));
    },
  );

  test('request ulang membawa body dan query yang sama', () async {
    final adapter = FakeHttpAdapter(
      (options) => authHeader(options) == 'Bearer token-2'
          ? jsonResponse({'id': 'n1'}, 201)
          : jsonResponse(errorBody('UNAUTHENTICATED'), 401),
    );

    await dioWith(adapter).post<Object?>(
      '/v1/notes',
      data: {'title': 'Judul'},
      queryParameters: {'x': '1'},
    );

    final [first, retry] = adapter.requests;
    expect(retry.method, 'POST');
    expect(retry.uri, first.uri);
    expect(retry.data, {'title': 'Judul'});
  });

  test('401 tanpa user login → tidak refresh dan tidak mengulang', () async {
    tokens.loggedIn = false;
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(errorBody('UNAUTHENTICATED'), 401),
    );

    await expectLater(
      dioWith(adapter).get<Object?>('/v1/me'),
      throwsA(isA<DioException>()),
    );
    expect(tokens.refreshCount, 0);
    expect(adapter.requests, hasLength(1));
  });

  test('error selain 401 tidak memicu refresh', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse(errorBody('FORBIDDEN'), 403),
    );

    await expectLater(
      dioWith(adapter).get<Object?>('/v1/me'),
      throwsA(isA<DioException>()),
    );
    expect(tokens.refreshCount, 0);
    expect(adapter.requests, hasLength(1));
  });

  test(
    'gagal refresh token → error 401 asli diteruskan tanpa mengulang',
    () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse(errorBody('UNAUTHENTICATED'), 401),
      );
      final dio = createDio(
        baseUrl: 'http://api.test',
        tokens: _ThrowingOnRefresh(),
      )..httpClientAdapter = adapter;

      await expectLater(
        dio.get<Object?>('/v1/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      expect(adapter.requests, hasLength(1));
    },
  );

  test(
    'gagal membaca token → request tidak dikirim, error menjadi DioException',
    () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse({'ok': true}, 200));
      final dio = createDio(
        baseUrl: 'http://api.test',
        tokens: _ThrowingAlways(),
      )..httpClientAdapter = adapter;

      await expectLater(
        dio.get<Object?>('/v1/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<StateError>(),
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
    },
  );
}

class _ThrowingOnRefresh implements TokenProvider {
  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    if (forceRefresh) throw StateError('network');
    return 'token-1';
  }
}

class _ThrowingAlways implements TokenProvider {
  @override
  Future<String?> idToken({bool forceRefresh = false}) async =>
      throw StateError('network');
}
