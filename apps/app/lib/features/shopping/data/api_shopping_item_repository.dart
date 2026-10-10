import 'package:app/core/error/result.dart';
import 'package:app/core/network/api_call.dart';
import 'package:app/features/shopping/data/shopping_item_mapper.dart';
import 'package:app/features/shopping/data/shopping_item_remote_data_source.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_page.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';

/// [ShoppingItemRepository] di atas API (`/v1/shopping-items`).
///
/// `DioException` dari [ShoppingItemRemoteDataSource] → `Err` lewat [apiCall], termasuk
/// `NOT_FOUND`, `CONFLICT` (nama sudah ada), dan `VALIDATION_ERROR` beserta `details`
/// (menjadi `Failure.fieldErrors`).
class ApiShoppingItemRepository implements ShoppingItemRepository {
  const ApiShoppingItemRepository(this._remote);

  final ShoppingItemRemoteDataSource _remote;

  @override
  Future<Result<ShoppingItemPage>> list({
    ShoppingItemStatus? status,
    String? cursor,
    int? limit,
  }) => apiCall(
    () => _remote.list(
      status: status == null ? null : shoppingItemStatusToDto(status),
      cursor: cursor,
      limit: limit,
    ),
    map: shoppingItemPageFromDto,
  );

  @override
  Future<Result<ShoppingItem>> create({required String name, int? quantity}) =>
      apiCall(
        () => _remote.create(name: name, quantity: quantity),
        map: shoppingItemFromDto,
      );

  @override
  Future<Result<ShoppingItem>> update(
    String id, {
    String? name,
    int? quantity,
    bool? isDone,
  }) => apiCall(
    () => _remote.update(id, name: name, quantity: quantity, isDone: isDone),
    map: shoppingItemFromDto,
  );

  @override
  Future<Result<void>> delete(String id) =>
      apiCallRaw(() => _remote.delete(id));

  @override
  Future<Result<int>> clearDone() =>
      apiCall(_remote.clearDone, map: (result) => result.deletedCount);
}
