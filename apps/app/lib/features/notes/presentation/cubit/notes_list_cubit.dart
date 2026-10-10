import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/usecases/list_notes.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_state.dart';

/// Daftar note dengan pagination cursor (muat halaman berikutnya saat digulir ke bawah).
///
/// Perubahan dari halaman form diterapkan langsung ke daftar ([noteSaved], [noteDeleted])
/// tanpa memuat ulang dari API.
class NotesListCubit extends Cubit<NotesListState> {
  NotesListCubit(this._listNotes) : super(const NotesListLoading());

  final ListNotes _listNotes;
  bool _loadingFirstPage = false;

  /// Memuat halaman pertama (juga untuk "coba lagi" setelah gagal).
  Future<void> load() async {
    if (_loadingFirstPage) return;
    _loadingFirstPage = true;
    emit(const NotesListLoading());
    final result = await _listNotes();
    _loadingFirstPage = false;
    if (isClosed) return;
    emit(switch (result) {
      Ok(value: final page) => NotesListLoaded(
        items: List.unmodifiable(page.items),
        nextCursor: page.nextCursor,
      ),
      Err(:final failure) => NotesListLoadFailed(failure),
    });
  }

  /// Memuat halaman berikutnya memakai `nextCursor`. Diabaikan bila daftar belum tampil,
  /// semua sudah dimuat, atau halaman berikutnya sedang dimuat.
  Future<void> loadMore() async {
    final current = state;
    if (current is! NotesListLoaded ||
        !current.hasMore ||
        current.loadingMore) {
      return;
    }
    emit(current.copyWith(loadingMore: true, loadMoreFailure: () => null));
    final result = await _listNotes(cursor: current.nextCursor);
    // Daftar bisa berubah selama menunggu (note disimpan atau dihapus), jadi baca ulang.
    final latest = state;
    if (isClosed || latest is! NotesListLoaded) return;
    emit(switch (result) {
      Ok(value: final page) => latest.copyWith(
        items: List.unmodifiable([...latest.items, ...page.items]),
        nextCursor: () => page.nextCursor,
        loadingMore: false,
      ),
      Err(:final failure) => latest.copyWith(
        loadingMore: false,
        loadMoreFailure: () => failure,
      ),
    });
  }

  /// Note dibuat atau diubah: ganti yang lama di tempatnya, atau taruh paling atas bila baru
  /// (urutan API: terbaru dibuat lebih dulu).
  void noteSaved(Note note) {
    final current = state;
    if (current is! NotesListLoaded) return;
    final exists = current.items.any((n) => n.id == note.id);
    final items = exists
        ? [for (final n in current.items) n.id == note.id ? note : n]
        : [note, ...current.items];
    emit(current.copyWith(items: List.unmodifiable(items)));
  }

  void noteDeleted(String id) {
    final current = state;
    if (current is! NotesListLoaded) return;
    emit(
      current.copyWith(
        items: List.unmodifiable(current.items.where((n) => n.id != id)),
      ),
    );
  }
}
