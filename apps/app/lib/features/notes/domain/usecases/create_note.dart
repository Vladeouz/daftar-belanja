import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';

/// Membuat note. Judul dirapikan (spasi di tepi dibuang), isi dikirim apa adanya.
///
/// Aturan panjang ditegakkan API; judul kosong kembali sebagai `fieldErrors['title']`.
class CreateNote {
  const CreateNote(this._repository);

  final NoteRepository _repository;

  Future<Result<Note>> call({required String title, String? body}) =>
      _repository.create(title: title.trim(), body: body);
}
