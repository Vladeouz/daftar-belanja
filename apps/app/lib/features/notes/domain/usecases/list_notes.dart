import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note_page.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';

/// Satu halaman note milik user. Tanpa [cursor] = halaman pertama.
class ListNotes {
  const ListNotes(this._repository);

  final NoteRepository _repository;

  Future<Result<NotePage>> call({String? cursor, int? limit}) =>
      _repository.list(cursor: cursor, limit: limit);
}
