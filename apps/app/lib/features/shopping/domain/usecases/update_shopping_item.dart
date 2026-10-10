import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';

/// Mengubah nama, jumlah, dan/atau status barang (termasuk menandai sudah/belum dibeli).
/// Field `null` tidak diubah; nama dirapikan.
class UpdateShoppingItem {
  const UpdateShoppingItem(this._repository);

  final ShoppingItemRepository _repository;

  Future<Result<ShoppingItem>> call(
    String id, {
    String? name,
    int? quantity,
    bool? isDone,
  }) => _repository.update(
    id,
    name: name?.trim(),
    quantity: quantity,
    isDone: isDone,
  );
}
