import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';

/// Satu note milik user.
class GetNote {
  const GetNote(this._repository);

  final NoteRepository _repository;

  Future<Result<Note>> call(String id) => _repository.get(id);
}
