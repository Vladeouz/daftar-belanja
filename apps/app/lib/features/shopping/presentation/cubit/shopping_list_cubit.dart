import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';
import 'package:app/features/shopping/domain/usecases/clear_done_shopping_items.dart';
import 'package:app/features/shopping/domain/usecases/list_shopping_items.dart';
import 'package:app/features/shopping/domain/usecases/update_shopping_item.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_list_state.dart';

/// Daftar belanja dengan filter status dan pagination cursor (muat halaman berikutnya saat
/// digulir ke bawah). State awal: memuat filter "Semua"; router memanggil [load].
///
/// Menandai sudah/belum dibeli ([toggleDone]) dan "Hapus yang sudah dibeli" ([clearDone])
/// disimpan ke API lalu diterapkan ke daftar tanpa memuat ulang. Perubahan dari halaman
/// form diterapkan lewat [itemSaved] dan [itemDeleted].
class ShoppingListCubit extends Cubit<ShoppingListState> {
  ShoppingListCubit({
    required this._listItems,
    required this._updateItem,
    required this._clearDone,
  }) : super(const ShoppingListLoading(ShoppingItemStatus.all));

  final ListShoppingItems _listItems;
  final UpdateShoppingItem _updateItem;
  final ClearDoneShoppingItems _clearDone;

  /// Naik setiap halaman pertama dimuat. Hasil permintaan yang lebih lama (filter sudah
  /// diganti atau daftar dimuat ulang) dibuang.
  int _generation = 0;

  /// Filter yang halaman pertamanya sedang dimuat; `null` bila tidak ada.
  ShoppingItemStatus? _loadingFilter;

  /// Memuat halaman pertama untuk filter yang sedang dipilih (juga untuk "coba lagi").
  Future<void> load() => _loadFirstPage(state.filter);

  /// Mengganti filter lalu memuat halaman pertamanya. Diabaikan bila filter sama.
  Future<void> setFilter(ShoppingItemStatus filter) async {
    if (filter == state.filter) return;
    await _loadFirstPage(filter);
  }

  Future<void> _loadFirstPage(ShoppingItemStatus filter) async {
    // Permintaan kedua untuk filter yang sama selagi masih dimuat tidak menambah apa pun.
    if (_loadingFilter == filter) return;
    final generation = ++_generation;
    _loadingFilter = filter;
    emit(ShoppingListLoading(filter));
    final result = await _listItems(status: filter);
    if (isClosed || generation != _generation) return;
    _loadingFilter = null;
    emit(switch (result) {
      Ok(value: final page) => ShoppingListLoaded(
        filter,
        items: List.unmodifiable(page.items),
        nextCursor: page.nextCursor,
      ),
      Err(:final failure) => ShoppingListLoadFailed(filter, failure),
    });
  }

  /// Memuat halaman berikutnya memakai `nextCursor`. Diabaikan bila daftar belum tampil,
  /// semua sudah dimuat, atau halaman berikutnya sedang dimuat.
  Future<void> loadMore() async {
    final current = state;
    if (current is! ShoppingListLoaded ||
        !current.hasMore ||
        current.loadingMore) {
      return;
    }
    final generation = _generation;
    emit(current.copyWith(loadingMore: true, loadMoreFailure: () => null));
    final result = await _listItems(
      status: current.filter,
      cursor: current.nextCursor,
    );
    // Daftar bisa berubah selama menunggu (barang ditandai, disimpan, atau filter diganti),
    // jadi baca ulang.
    final latest = state;
    if (isClosed ||
        generation != _generation ||
        latest is! ShoppingListLoaded) {
      return;
    }
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

  /// Membalik status sudah/belum dibeli [item]. Barang yang tidak lagi cocok dengan filter
  /// (misalnya ditandai sudah dibeli saat filter "Belum") hilang dari daftar. Bila gagal,
  /// daftar tetap dan [ShoppingListLoaded.actionFailure] terisi. Diabaikan selagi status
  /// barang yang sama masih disimpan.
  Future<void> toggleDone(ShoppingItem item) async {
    final current = state;
    if (current is! ShoppingListLoaded ||
        current.updatingIds.contains(item.id)) {
      return;
    }
    final generation = _generation;
    emit(
      current.copyWith(
        updatingIds: {...current.updatingIds, item.id},
        actionFailure: () => null,
      ),
    );
    final result = await _updateItem(item.id, isDone: !item.isDone);
    final latest = state;
    if (isClosed ||
        generation != _generation ||
        latest is! ShoppingListLoaded) {
      return;
    }
    final updatingIds = {...latest.updatingIds}..remove(item.id);
    emit(switch (result) {
      Ok(value: final updated) => latest.copyWith(
        items: _withSaved(latest, updated),
        updatingIds: updatingIds,
      ),
      Err(:final failure) => latest.copyWith(
        updatingIds: updatingIds,
        actionFailure: () => failure,
      ),
    });
  }

  /// Menghapus semua barang yang sudah dibeli (milik user, termasuk yang belum dimuat).
  /// Barang yang sudah dibeli dibuang dari daftar; cursor tetap berlaku karena berbasis
  /// posisi, jadi halaman berikutnya dari API sudah tanpa barang itu.
  Future<void> clearDone() async {
    final current = state;
    if (current is! ShoppingListLoaded || current.clearing) return;
    final generation = _generation;
    emit(current.copyWith(clearing: true, actionFailure: () => null));
    final result = await _clearDone();
    final latest = state;
    if (isClosed ||
        generation != _generation ||
        latest is! ShoppingListLoaded) {
      return;
    }
    emit(switch (result) {
      Ok() => latest.copyWith(
        items: List.unmodifiable(latest.items.where((i) => !i.isDone)),
        clearing: false,
      ),
      Err(:final failure) => latest.copyWith(
        clearing: false,
        actionFailure: () => failure,
      ),
    });
  }

  /// Barang dibuat atau diubah di form: ganti yang lama di tempatnya, atau taruh paling atas
  /// bila baru (urutan API: terbaru dibuat lebih dulu). Barang yang tidak cocok dengan
  /// filter dibuang dari daftar.
  void itemSaved(ShoppingItem item) {
    final current = state;
    if (current is! ShoppingListLoaded) return;
    emit(current.copyWith(items: _withSaved(current, item)));
  }

  void itemDeleted(String id) {
    final current = state;
    if (current is! ShoppingListLoaded) return;
    emit(
      current.copyWith(
        items: List.unmodifiable(current.items.where((i) => i.id != id)),
      ),
    );
  }

  static List<ShoppingItem> _withSaved(
    ShoppingListLoaded state,
    ShoppingItem item,
  ) {
    final matches = _matches(state.filter, item);
    final exists = state.items.any((i) => i.id == item.id);
    final items = exists
        ? [
            for (final i in state.items)
              if (i.id != item.id) i else if (matches) item,
          ]
        : [if (matches) item, ...state.items];
    return List.unmodifiable(items);
  }

  static bool _matches(ShoppingItemStatus filter, ShoppingItem item) =>
      switch (filter) {
        ShoppingItemStatus.all => true,
        ShoppingItemStatus.open => !item.isDone,
        ShoppingItemStatus.done => item.isDone,
      };
}
