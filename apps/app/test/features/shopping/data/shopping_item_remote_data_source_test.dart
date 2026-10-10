import 'package:api_client/api_client.dart' as dto;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/shopping/data/shopping_item_remote_data_source.dart';

import '../../../core/network/fake_http_adapter.dart';
import '../mocks.dart';

void main() {
  late FakeHttpAdapter adapter;
  late ShoppingItemRemoteDataSource remote;

  /// Data source di atas `ShoppingClient` asli; setiap request dijawab [respond].
  void setUpRemote(ResponseBody Function(RequestOptions) respond) {
    adapter = FakeHttpAdapter(respond);
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    remote = ShoppingItemRemoteDataSource(dto.ShoppingClient(dio));
  }

  RequestOptions lastRequest() => adapter.requests.single;

  group('list', () {
    setUp(
      () => setUpRemote(
        (_) => jsonResponse({
          'items': [shoppingItemJson],
          'nextCursor': 'c2',
        }, 200),
      ),
    );

    test('GET /v1/shopping-items dengan status, cursor, dan limit', () async {
      final page = await remote.list(
        status: dto.ShoppingItemStatus.open,
        cursor: 'c1',
        limit: 10,
      );

      expect(lastRequest().method, 'GET');
      expect(lastRequest().path, '/v1/shopping-items');
      expect(lastRequest().uri.queryParameters, {
        'status': 'open',
        'cursor': 'c1',
        'limit': '10',
      });
      expect(page.items.single.id, shoppingItemJson['id']);
      expect(page.nextCursor, 'c2');
    });

    test(
      'tanpa status, cursor, dan limit → query kosong (bawaan API)',
      () async {
        await remote.list();

        expect(lastRequest().uri.queryParameters, isEmpty);
      },
    );
  });

  group('barang tunggal', () {
    setUp(() => setUpRemote((_) => jsonResponse(shoppingItemJson, 200)));

    test('create → POST /v1/shopping-items dengan name dan quantity', () async {
      final item = await remote.create(name: 'Telur', quantity: 2);

      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/v1/shopping-items');
      expect(lastRequest().data, {'name': 'Telur', 'quantity': 2});
      expect(item.name, 'Telur');
    });

    test(
      'create tanpa quantity → quantity tidak dikirim (bukan null)',
      () async {
        await remote.create(name: 'Telur');

        expect(lastRequest().data, {'name': 'Telur'});
      },
    );

    test(
      'update hanya isDone → PATCH /v1/shopping-items/{id} berisi isDone saja',
      () async {
        await remote.update('s1', isDone: true);

        expect(lastRequest().method, 'PATCH');
        expect(lastRequest().path, '/v1/shopping-items/s1');
        expect(lastRequest().data, {'isDone': true});
      },
    );

    test('update hanya nama dan jumlah → isDone tidak dikirim', () async {
      await remote.update('s1', name: 'Susu', quantity: 3);

      expect(lastRequest().data, {'name': 'Susu', 'quantity': 3});
    });

    test('update isDone false tetap dikirim', () async {
      await remote.update('s1', isDone: false);

      expect(lastRequest().data, {'isDone': false});
    });
  });

  test('delete → DELETE /v1/shopping-items/{id} dengan respons 204', () async {
    setUpRemote((_) => ResponseBody.fromString('', 204));

    await remote.delete('s1');

    expect(lastRequest().method, 'DELETE');
    expect(lastRequest().path, '/v1/shopping-items/s1');
  });

  test('clearDone → POST /v1/shopping-items/clear-done tanpa body', () async {
    setUpRemote((_) => jsonResponse({'deletedCount': 3}, 200));

    final result = await remote.clearDone();

    expect(lastRequest().method, 'POST');
    expect(lastRequest().path, '/v1/shopping-items/clear-done');
    expect(lastRequest().data, isNull);
    expect(lastRequest().uri.queryParameters, isEmpty);
    expect(result.deletedCount, 3);
  });

  test('respons error dilempar sebagai DioException', () {
    setUpRemote((_) => jsonResponse(errorBody('CONFLICT'), 409));

    expect(
      remote.create(name: 'telur'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          409,
        ),
      ),
    );
  });
}
