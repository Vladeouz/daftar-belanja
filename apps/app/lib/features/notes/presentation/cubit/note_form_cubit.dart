import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/usecases/create_note.dart';
import 'package:app/features/notes/domain/usecases/delete_note.dart';
import 'package:app/features/notes/domain/usecases/get_note.dart';
import 'package:app/features/notes/domain/usecases/update_note.dart';
import 'package:app/features/notes/presentation/cubit/note_form_state.dart';

/// Form buat/ubah/hapus note. State awal: form note baru.
///
/// Router memanggil [edit] bila note sudah dibawa dari daftar, atau [load] bila halaman
/// dibuka langsung lewat URL.
class NoteFormCubit extends Cubit<NoteFormState> {
  NoteFormCubit({
    required this._getNote,
    required this._createNote,
    required this._updateNote,
    required this._deleteNote,
  }) : super(const NoteFormEditing());

  final GetNote _getNote;
  final CreateNote _createNote;
  final UpdateNote _updateNote;
  final DeleteNote _deleteNote;

  void edit(Note note) => emit(NoteFormEditing(note: note));

  Future<void> load(String id) async {
    if (state is NoteFormLoading) return;
    emit(const NoteFormLoading());
    final result = await _getNote(id);
    if (isClosed) return;
    emit(switch (result) {
      Ok(value: final note) => NoteFormEditing(note: note),
      Err(:final failure) => NoteFormLoadFailed(failure),
    });
  }

  /// Membuat note baru atau mengubah note yang dibuka. Diabaikan saat masih menyimpan
  /// atau menghapus. Error validasi API kembali ke form lewat `failure.fieldErrors`.
  Future<void> save({required String title, required String body}) async {
    final current = state;
    if (current is! NoteFormEditing || current.busy) return;
    emit(NoteFormEditing(note: current.note, status: NoteFormStatus.saving));
    final note = current.note;
    final result = note == null
        ? await _createNote(title: title, body: body)
        : await _updateNote(note.id, title: title, body: body);
    if (isClosed) return;
    emit(switch (result) {
      Ok(value: final saved) => NoteFormSaved(saved),
      Err(:final failure) => NoteFormEditing(note: note, failure: failure),
    });
  }

  /// Menghapus note yang dibuka. Diabaikan untuk note baru atau saat masih sibuk.
  Future<void> delete() async {
    final current = state;
    if (current is! NoteFormEditing || current.busy) return;
    final note = current.note;
    if (note == null) return;
    emit(NoteFormEditing(note: note, status: NoteFormStatus.deleting));
    final result = await _deleteNote(note.id);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => NoteFormDeleted(note.id),
      Err(:final failure) => NoteFormEditing(note: note, failure: failure),
    });
  }
}
