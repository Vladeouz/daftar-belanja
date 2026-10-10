import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';

/// Mengubah judul dan/atau isi note. Field `null` tidak diubah; judul dirapikan.
class UpdateNote {
  const UpdateNote(this._repository);

  final NoteRepository _repository;

  Future<Result<Note>> call(String id, {String? title, String? body}) =>
      _repository.update(id, title: title?.trim(), body: body);
}
