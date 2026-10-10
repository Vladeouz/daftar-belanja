import 'package:api_client/api_client.dart';
import 'package:get_it/get_it.dart';

import 'package:app/features/shopping/data/api_shopping_item_repository.dart';
import 'package:app/features/shopping/data/shopping_item_remote_data_source.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';
import 'package:app/features/shopping/domain/usecases/clear_done_shopping_items.dart';
import 'package:app/features/shopping/domain/usecases/create_shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/delete_shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/list_shopping_items.dart';
import 'package:app/features/shopping/domain/usecases/update_shopping_item.dart';

/// Dependency fitur shopping. Dipanggil dari `configureDependencies` (butuh `ApiClient`).
void registerShoppingDependencies(GetIt c) {
  c
    ..registerLazySingleton(
      () => ShoppingItemRemoteDataSource(c<ApiClient>().shopping),
    )
    ..registerLazySingleton<ShoppingItemRepository>(
      () => ApiShoppingItemRepository(c()),
    )
    ..registerLazySingleton(() => ListShoppingItems(c()))
    ..registerLazySingleton(() => CreateShoppingItem(c()))
    ..registerLazySingleton(() => UpdateShoppingItem(c()))
    ..registerLazySingleton(() => DeleteShoppingItem(c()))
    ..registerLazySingleton(() => ClearDoneShoppingItems(c()));
}
