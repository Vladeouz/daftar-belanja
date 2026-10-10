import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_page.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';

/// Satu halaman barang belanja milik user. Tanpa [cursor] = halaman pertama.
class ListShoppingItems {
  const ListShoppingItems(this._repository);

  final ShoppingItemRepository _repository;

  Future<Result<ShoppingItemPage>> call({
    ShoppingItemStatus? status,
    String? cursor,
    int? limit,
  }) => _repository.list(status: status, cursor: cursor, limit: limit);
}
