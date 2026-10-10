import 'package:api_client/api_client.dart' as dto;

/// Data source barang belanja di atas `ShoppingClient` hasil generate (`packages/contract/dart`).
///
/// Mengembalikan DTO apa adanya dan melempar `DioException` saat gagal; pemetaan ke entity
/// dan `Result` dilakukan `ApiShoppingItemRepository`.
class ShoppingItemRemoteDataSource {
  const ShoppingItemRemoteDataSource(this._client);

  final dto.ShoppingClient _client;

  Future<dto.ShoppingItemPage> list({
    dto.ShoppingItemStatus? status,
    String? cursor,
    int? limit,
  }) => _client.listShoppingItems(status: status, cursor: cursor, limit: limit);

  Future<dto.ShoppingItem> create({required String name, int? quantity}) =>
      _client.createShoppingItem(
        body: dto.CreateShoppingItemInput(name: name, quantity: quantity),
      );

  Future<dto.ShoppingItem> update(
    String id, {
    String? name,
    int? quantity,
    bool? isDone,
  }) => _client.updateShoppingItem(
    id: id,
    body: dto.UpdateShoppingItemInput(
      name: name,
      quantity: quantity,
      isDone: isDone,
    ),
  );

  Future<void> delete(String id) => _client.deleteShoppingItem(id: id);

  Future<dto.ClearDoneShoppingItemsResult> clearDone() =>
      _client.clearDoneShoppingItems();
}
