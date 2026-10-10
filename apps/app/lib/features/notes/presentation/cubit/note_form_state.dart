import 'package:equatable/equatable.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/notes/domain/entities/note.dart';

/// State form buat/ubah note (`NoteFormCubit`).
sealed class NoteFormState extends Equatable {
  const NoteFormState();

  @override
  List<Object?> get props => [];
}

/// Note yang akan diubah sedang dimuat (halaman dibuka lewat URL, tanpa data dari daftar).
final class NoteFormLoading extends NoteFormState {
  const NoteFormLoading();
}

/// Note gagal dimuat (tidak ada, milik user lain, atau gagal koneksi).
final class NoteFormLoadFailed extends NoteFormState {
  const NoteFormLoadFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

enum NoteFormStatus { idle, saving, deleting }

/// Form tampil. [note] `null` = membuat note baru.
final class NoteFormEditing extends NoteFormState {
  const NoteFormEditing({
    this.note,
    this.status = NoteFormStatus.idle,
    this.failure,
  });

  final Note? note;
  final NoteFormStatus status;

  /// Kegagalan simpan atau hapus terakhir. Error validasi API ada di `failure.fieldErrors`
  /// (`title`, `body`) dan ditampilkan di field-nya.
  final Failure? failure;

  bool get isNew => note == null;
  bool get busy => status != NoteFormStatus.idle;

  @override
  List<Object?> get props => [note, status, failure];
}

/// Tersimpan. Halaman kembali ke daftar membawa note ini.
final class NoteFormSaved extends NoteFormState {
  const NoteFormSaved(this.note);

  final Note note;

  @override
  List<Object?> get props => [note];
}

/// Terhapus. Halaman kembali ke daftar membawa id ini.
final class NoteFormDeleted extends NoteFormState {
  const NoteFormDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
