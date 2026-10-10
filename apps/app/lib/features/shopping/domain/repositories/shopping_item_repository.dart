import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_page.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';

/// Barang belanja milik user yang login. Implementasi: `ApiShoppingItemRepository`.
///
/// Barang milik user lain atau yang sudah dihapus → `Err` dengan `FailureCode.notFound`.
/// Nama yang sudah ada di daftar → `FailureCode.conflict`.
/// Input yang ditolak API → `FailureCode.validation` dengan `fieldErrors` per field.
abstract interface class ShoppingItemRepository {
  /// [status] `null` = bawaan API (semua); [cursor] dari `ShoppingItemPage.nextCursor`
  /// halaman sebelumnya; [limit] `null` = bawaan API (20).
  Future<Result<ShoppingItemPage>> list({
    ShoppingItemStatus? status,
    String? cursor,
    int? limit,
  });

  /// [quantity] `null` = tidak dikirim (API menyimpan 1).
  Future<Result<ShoppingItem>> create({required String name, int? quantity});

  /// Field `null` tidak diubah. API menolak bila semuanya `null` (`fieldErrors['_root']`).
  Future<Result<ShoppingItem>> update(
    String id, {
    String? name,
    int? quantity,
    bool? isDone,
  });

  Future<Result<void>> delete(String id);

  /// Menghapus semua barang yang sudah dibeli; nilainya jumlah barang yang terhapus.
  Future<Result<int>> clearDone();
}
