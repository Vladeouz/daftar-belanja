import 'package:equatable/equatable.dart';

import 'package:app/features/shopping/domain/entities/shopping_item.dart';

/// Satu halaman daftar belanja, terbaru lebih dulu (pagination cursor).
class ShoppingItemPage extends Equatable {
  const ShoppingItemPage({required this.items, required this.nextCursor});

  final List<ShoppingItem> items;

  /// Dikirim ke `ListShoppingItems` untuk halaman berikutnya; `null` di halaman terakhir.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [items, nextCursor];
}
