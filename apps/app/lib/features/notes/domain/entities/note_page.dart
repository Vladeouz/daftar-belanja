import 'package:equatable/equatable.dart';

import 'package:app/features/notes/domain/entities/note.dart';

/// Satu halaman daftar note, terbaru lebih dulu (pagination cursor, PRD bagian 3).
class NotePage extends Equatable {
  const NotePage({required this.items, required this.nextCursor});

  final List<Note> items;

  /// Dikirim ke `ListNotes` untuk halaman berikutnya; `null` di halaman terakhir.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [items, nextCursor];
}
