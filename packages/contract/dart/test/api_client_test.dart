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

const note = {
  'id': '6f1c2f0e-8a3b-4c5d-9e7f-0a1b2c3d4e5f',
  'title': 'Belanja',
  'body': 'Susu dan roti',
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

  test('NotesClient.listNotes membaca NotePage dan mengirim query', () async {
    final adapter = FakeAdapter(200, {
      'items': [note],
      'nextCursor': null,
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter;

    final page = await NotesClient(dio).listNotes(cursor: 'abc', limit: 10);

    expect(page.items.single.title, 'Belanja');
    expect(page.items.single.createdAt, DateTime.utc(2026, 10, 1, 8, 30));
    expect(page.nextCursor, isNull);
    expect(
      adapter.lastRequest!.uri.toString(),
      'http://localhost:3000/v1/notes?cursor=abc&limit=10',
    );
  });

  test('respons 404 sampai sebagai DioException berisi ErrorBody', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = FakeAdapter(404, {
        'error': {'code': 'NOT_FOUND', 'message': 'Note not found'},
      });

    await expectLater(
      NotesClient(dio).getNote(id: note['id']!),
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
    expect(const UpdateNoteInput(body: 'Isi').toJson(), {'body': 'Isi'});
    expect(const UpdateNoteInput(title: 'Judul').toJson(), {'title': 'Judul'});
    expect(const CreateNoteInput(title: 'Judul').toJson(), {'title': 'Judul'});
  });

  test('field wajib yang nullable tetap dikirim sebagai null', () {
    expect(const NotePage(items: [], nextCursor: null).toJson(), {
      'items': <Object?>[],
      'nextCursor': null,
    });
  });
}
