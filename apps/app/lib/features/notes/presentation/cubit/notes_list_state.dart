import 'package:equatable/equatable.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/notes/domain/entities/note.dart';

/// State daftar note (`NotesListCubit`).
sealed class NotesListState extends Equatable {
  const NotesListState();

  @override
  List<Object?> get props => [];
}

/// Halaman pertama sedang dimuat.
final class NotesListLoading extends NotesListState {
  const NotesListLoading();
}

/// Halaman pertama gagal dimuat; halaman menampilkan pesan dan tombol coba lagi.
final class NotesListLoadFailed extends NotesListState {
  const NotesListLoadFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Daftar sudah tampil (boleh kosong).
final class NotesListLoaded extends NotesListState {
  const NotesListLoaded({
    required this.items,
    required this.nextCursor,
    this.loadingMore = false,
    this.loadMoreFailure,
  });

  /// Terbaru lebih dulu, gabungan semua halaman yang sudah dimuat.
  final List<Note> items;

  /// Cursor halaman berikutnya; `null` bila semua sudah dimuat.
  final String? nextCursor;

  /// Halaman berikutnya sedang dimuat.
  final bool loadingMore;

  /// Halaman berikutnya gagal dimuat; dicoba lagi lewat `loadMore()`.
  final Failure? loadMoreFailure;

  bool get hasMore => nextCursor != null;

  NotesListLoaded copyWith({
    List<Note>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    Failure? Function()? loadMoreFailure,
  }) => NotesListLoaded(
    items: items ?? this.items,
    nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailure: loadMoreFailure != null
        ? loadMoreFailure()
        : this.loadMoreFailure,
  );

  @override
  List<Object?> get props => [items, nextCursor, loadingMore, loadMoreFailure];
}
