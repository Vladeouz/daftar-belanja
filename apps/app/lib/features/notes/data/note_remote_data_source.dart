import 'package:api_client/api_client.dart' as dto;

/// Data source notes di atas `NotesClient` hasil generate (`packages/contract/dart`).
///
/// Mengembalikan DTO apa adanya dan melempar `DioException` saat gagal; pemetaan ke entity
/// dan `Result` dilakukan `ApiNoteRepository`.
class NoteRemoteDataSource {
  const NoteRemoteDataSource(this._client);

  final dto.NotesClient _client;

  Future<dto.NotePage> list({String? cursor, int? limit}) =>
      _client.listNotes(cursor: cursor, limit: limit);

  Future<dto.Note> get(String id) => _client.getNote(id: id);

  Future<dto.Note> create({required String title, String? body}) =>
      _client.createNote(
        body: dto.CreateNoteInput(title: title, body: body),
      );

  Future<dto.Note> update(String id, {String? title, String? body}) =>
      _client.updateNote(
        id: id,
        body: dto.UpdateNoteInput(title: title, body: body),
      );

  Future<void> delete(String id) => _client.deleteNote(id: id);
}
