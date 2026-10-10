import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';

/// Menghapus note milik user.
class DeleteNote {
  const DeleteNote(this._repository);

  final NoteRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}
