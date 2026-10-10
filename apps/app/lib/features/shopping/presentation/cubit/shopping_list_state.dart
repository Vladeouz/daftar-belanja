import 'package:equatable/equatable.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';

/// State daftar belanja (`ShoppingListCubit`). Setiap state membawa [filter] yang sedang
/// dipilih agar pilihan filter tetap tampil selama memuat atau setelah gagal.
sealed class ShoppingListState extends Equatable {
  const ShoppingListState(this.filter);

  final ShoppingItemStatus filter;

  @override
  List<Object?> get props => [filter];
}

/// Halaman pertama untuk [filter] sedang dimuat.
final class ShoppingListLoading extends ShoppingListState {
  const ShoppingListLoading(super.filter);
}

/// Halaman pertama gagal dimuat; halaman menampilkan pesan dan tombol coba lagi.
final class ShoppingListLoadFailed extends ShoppingListState {
  const ShoppingListLoadFailed(super.filter, this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [filter, failure];
}

/// Daftar sudah tampil (boleh kosong).
final class ShoppingListLoaded extends ShoppingListState {
  const ShoppingListLoaded(
    super.filter, {
    required this.items,
    required this.nextCursor,
    this.loadingMore = false,
    this.loadMoreFailure,
    this.updatingIds = const {},
    this.clearing = false,
    this.actionFailure,
  });

  /// Terbaru lebih dulu, gabungan semua halaman yang sudah dimuat; hanya barang yang
  /// cocok dengan [filter].
  final List<ShoppingItem> items;

  /// Cursor halaman berikutnya; `null` bila semua sudah dimuat.
  final String? nextCursor;

  /// Halaman berikutnya sedang dimuat.
  final bool loadingMore;

  /// Halaman berikutnya gagal dimuat; dicoba lagi lewat `loadMore()`.
  final Failure? loadMoreFailure;

  /// Barang yang status sudah/belum dibelinya sedang disimpan.
  final Set<String> updatingIds;

  /// "Hapus yang sudah dibeli" sedang berjalan.
  final bool clearing;

  /// Kegagalan aksi terakhir (tandai atau hapus yang sudah dibeli); tampil sebagai SnackBar.
  /// Dikosongkan setiap aksi baru dimulai.
  final Failure? actionFailure;

  bool get hasMore => nextCursor != null;

  ShoppingListLoaded copyWith({
    List<ShoppingItem>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    Failure? Function()? loadMoreFailure,
    Set<String>? updatingIds,
    bool? clearing,
    Failure? Function()? actionFailure,
  }) => ShoppingListLoaded(
    filter,
    items: items ?? this.items,
    nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailure: loadMoreFailure != null
        ? loadMoreFailure()
        : this.loadMoreFailure,
    updatingIds: updatingIds ?? this.updatingIds,
    clearing: clearing ?? this.clearing,
    actionFailure: actionFailure != null ? actionFailure() : this.actionFailure,
  );

  @override
  List<Object?> get props => [
    filter,
    items,
    nextCursor,
    loadingMore,
    loadMoreFailure,
    updatingIds,
    clearing,
    actionFailure,
  ];
}
