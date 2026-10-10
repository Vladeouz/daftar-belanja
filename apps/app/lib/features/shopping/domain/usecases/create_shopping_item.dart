import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';

/// Menambah barang. Nama dirapikan (spasi di tepi dibuang).
///
/// Aturan panjang dan jumlah ditegakkan API; nama kosong kembali sebagai
/// `fieldErrors['name']`, nama yang sudah ada sebagai `FailureCode.conflict`.
class CreateShoppingItem {
  const CreateShoppingItem(this._repository);

  final ShoppingItemRepository _repository;

  Future<Result<ShoppingItem>> call({required String name, int? quantity}) =>
      _repository.create(name: name.trim(), quantity: quantity);
}
