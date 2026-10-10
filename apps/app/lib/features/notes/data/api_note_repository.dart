import 'package:app/core/error/result.dart';
import 'package:app/core/network/api_call.dart';
import 'package:app/features/notes/data/note_mapper.dart';
import 'package:app/features/notes/data/note_remote_data_source.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/entities/note_page.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';

/// [NoteRepository] di atas API (`/v1/notes`).
///
/// `DioException` dari [NoteRemoteDataSource] → `Err` lewat [apiCall], termasuk `NOT_FOUND`
/// dan `VALIDATION_ERROR` beserta `details` (menjadi `Failure.fieldErrors`).
class ApiNoteRepository implements NoteRepository {
  const ApiNoteRepository(this._remote);

  final NoteRemoteDataSource _remote;

  @override
  Future<Result<NotePage>> list({String? cursor, int? limit}) => apiCall(
    () => _remote.list(cursor: cursor, limit: limit),
    map: notePageFromDto,
  );

  @override
  Future<Result<Note>> get(String id) =>
      apiCall(() => _remote.get(id), map: noteFromDto);

  @override
  Future<Result<Note>> create({required String title, String? body}) => apiCall(
    () => _remote.create(title: title, body: body),
    map: noteFromDto,
  );

  @override
  Future<Result<Note>> update(String id, {String? title, String? body}) =>
      apiCall(
        () => _remote.update(id, title: title, body: body),
        map: noteFromDto,
      );

  @override
  Future<Result<void>> delete(String id) =>
      apiCallRaw(() => _remote.delete(id));
}
