import 'package:api_client/api_client.dart' as dto;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/notes/data/note_remote_data_source.dart';

import '../../../core/network/fake_http_adapter.dart';
import '../mocks.dart';

void main() {
  late FakeHttpAdapter adapter;
  late NoteRemoteDataSource remote;

  /// Data source di atas `NotesClient` asli; setiap request dijawab [respond].
  void setUpRemote(ResponseBody Function(RequestOptions) respond) {
    adapter = FakeHttpAdapter(respond);
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    remote = NoteRemoteDataSource(dto.NotesClient(dio));
  }

  RequestOptions lastRequest() => adapter.requests.single;

  group('list', () {
    setUp(
      () => setUpRemote(
        (_) => jsonResponse({
          'items': [noteJson],
          'nextCursor': 'c2',
        }, 200),
      ),
    );

    test('GET /v1/notes dengan cursor dan limit', () async {
      final page = await remote.list(cursor: 'c1', limit: 10);

      expect(lastRequest().method, 'GET');
      expect(lastRequest().path, '/v1/notes');
      expect(lastRequest().queryParameters, {'cursor': 'c1', 'limit': 10});
      expect(page.items.single.id, noteJson['id']);
      expect(page.nextCursor, 'c2');
    });

    test('tanpa cursor dan limit → query kosong (bawaan API)', () async {
      await remote.list();

      expect(lastRequest().queryParameters, isEmpty);
    });
  });

  group('note tunggal', () {
    setUp(() => setUpRemote((_) => jsonResponse(noteJson, 200)));

    test('get → GET /v1/notes/{id}', () async {
      final note = await remote.get('n1');

      expect(lastRequest().method, 'GET');
      expect(lastRequest().path, '/v1/notes/n1');
      expect(note.title, 'Belanja');
    });

    test('create → POST /v1/notes dengan title dan body', () async {
      await remote.create(title: 'Belanja', body: 'Susu');

      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/v1/notes');
      expect(lastRequest().data, {'title': 'Belanja', 'body': 'Susu'});
    });

    test('create tanpa body → body tidak dikirim (bukan null)', () async {
      await remote.create(title: 'Belanja');

      expect(lastRequest().data, {'title': 'Belanja'});
    });

    test(
      'update → PATCH /v1/notes/{id} hanya dengan field yang diisi',
      () async {
        await remote.update('n1', body: '');

        expect(lastRequest().method, 'PATCH');
        expect(lastRequest().path, '/v1/notes/n1');
        expect(lastRequest().data, {'body': ''});
      },
    );

    test('update dengan kedua field', () async {
      await remote.update('n1', title: 'Judul', body: 'Isi');

      expect(lastRequest().data, {'title': 'Judul', 'body': 'Isi'});
    });
  });

  test('delete → DELETE /v1/notes/{id} dengan respons 204', () async {
    setUpRemote((_) => ResponseBody.fromString('', 204));

    await remote.delete('n1');

    expect(lastRequest().method, 'DELETE');
    expect(lastRequest().path, '/v1/notes/n1');
  });

  test('respons error dilempar sebagai DioException', () {
    setUpRemote((_) => jsonResponse(errorBody('NOT_FOUND'), 404));

    expect(
      remote.get('n1'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          404,
        ),
      ),
    );
  });
}
