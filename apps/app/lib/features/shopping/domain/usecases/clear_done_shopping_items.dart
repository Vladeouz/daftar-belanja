import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';

/// Menghapus semua barang yang sudah dibeli; nilainya jumlah barang yang terhapus.
class ClearDoneShoppingItems {
  const ClearDoneShoppingItems(this._repository);

  final ShoppingItemRepository _repository;

  Future<Result<int>> call() => _repository.clearDone();
}
