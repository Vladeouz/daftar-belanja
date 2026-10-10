import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';

/// Menghapus satu barang milik user.
class DeleteShoppingItem {
  const DeleteShoppingItem(this._repository);

  final ShoppingItemRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}
