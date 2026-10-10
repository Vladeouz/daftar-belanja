import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Adapter dio palsu: selalu menjawab dengan status dan body yang diberikan.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.status, this.body);

  final int status;
  final Object body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const shoppingItem = {
  'id': '6f1c2f0e-8a3b-4c5d-9e7f-0a1b2c3d4e5f',
  'name': 'Susu',
  'quantity': 2,
  'isDone': false,
  'createdAt': '2026-10-01T08:30:00.000Z',
  'updatedAt': '2026-10-01T09:00:00.000Z',
};

void main() {
  test('ErrorCode sama dengan daftar PRD bagian 5', () {
    expect(ErrorCode.$valuesDefined.map((code) => code.json), [
      'BAD_REQUEST',
      'UNAUTHENTICATED',
      'FORBIDDEN',
      'NOT_FOUND',
      'CONFLICT',
      'VALIDATION_ERROR',
      'INTERNAL_ERROR',
    ]);
  });

  test('ErrorBody 422 dengan details', () {
    final body = ErrorBody.fromJson({
      'error': {
        'code': 'VALIDATION_ERROR',
        'message': 'Request validation failed',
        'details': {
          'title': [
            {'code': 'required', 'message': 'Required'},
          ],
          '_root': [
            {'code': 'custom', 'message': 'At least one field is required'},
          ],
        },
      },
    });

    expect(body.error.code, ErrorCode.validationError);
    expect(body.error.details!['title']!.single.code, 'required');
    expect(body.error.details!['_root']!.single.code, 'custom');
  });

  test('ErrorCode yang belum dikenal menjadi \$unknown', () {
    final body = ErrorBody.fromJson({
      'error': {'code': 'TOO_MANY_REQUESTS', 'message': 'Slow down'},
    });

    expect(body.error.code, ErrorCode.$unknown);
    expect(body.error.details, isNull);
  });

  test('ShoppingClient.listShoppingItems membaca ShoppingItemPage dan mengirim query', () async {
    final adapter = FakeAdapter(200, {
      'items': [shoppingItem],
      'nextCursor': null,
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter;

    final page = await ShoppingClient(dio).listShoppingItems(
      cursor: 'abc',
      status: ShoppingItemStatus.open,
      limit: 10,
    );

    expect(page.items.single.name, 'Susu');
    expect(page.items.single.createdAt, DateTime.utc(2026, 10, 1, 8, 30));
    expect(page.nextCursor, isNull);
    expect(
      adapter.lastRequest!.uri.toString(),
      'http://localhost:3000/v1/shopping-items?cursor=abc&status=open&limit=10',
    );
  });

  test('respons 404 sampai sebagai DioException berisi ErrorBody', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = FakeAdapter(404, {
        'error': {'code': 'NOT_FOUND', 'message': 'Shopping item not found'},
      });

    await expectLater(
      ShoppingClient(dio).deleteShoppingItem(id: shoppingItem['id']! as String),
      throwsA(
        isA<DioException>().having(
          (e) =>
              ErrorBody.fromJson(e.response!.data as Map<String, Object?>)
                  .error
                  .code,
          'error.code',
          ErrorCode.notFound,
        ),
      ),
    );
  });

  test('field opsional yang null tidak dikirim di body request', () {
    expect(const UpdateShoppingItemInput(isDone: true).toJson(), {
      'isDone': true,
    });
    expect(const UpdateShoppingItemInput(name: 'Susu').toJson(), {
      'name': 'Susu',
    });
    expect(const CreateShoppingItemInput(name: 'Susu').toJson(), {
      'name': 'Susu',
    });
  });

  test('field wajib yang nullable tetap dikirim sebagai null', () {
    expect(const ShoppingItemPage(items: [], nextCursor: null).toJson(), {
      'items': <Object?>[],
      'nextCursor': null,
    });
  });
}
