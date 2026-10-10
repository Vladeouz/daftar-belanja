import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/features/shopping/data/shopping_item_remote_data_source.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';
import 'package:app/features/shopping/domain/usecases/clear_done_shopping_items.dart';
import 'package:app/features/shopping/domain/usecases/create_shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/delete_shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/list_shopping_items.dart';
import 'package:app/features/shopping/domain/usecases/update_shopping_item.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_cubit.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_state.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_list_cubit.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_list_state.dart';

class MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class MockShoppingItemRemoteDataSource extends Mock
    implements ShoppingItemRemoteDataSource {}

class MockListShoppingItems extends Mock implements ListShoppingItems {}

class MockCreateShoppingItem extends Mock implements CreateShoppingItem {}

class MockUpdateShoppingItem extends Mock implements UpdateShoppingItem {}

class MockDeleteShoppingItem extends Mock implements DeleteShoppingItem {}

class MockClearDoneShoppingItems extends Mock
    implements ClearDoneShoppingItems {}

class MockShoppingListCubit extends MockCubit<ShoppingListState>
    implements ShoppingListCubit {}

class MockShoppingItemFormCubit extends MockCubit<ShoppingItemFormState>
    implements ShoppingItemFormCubit {}

/// Barang contoh untuk test, sama dengan [shoppingItemJson].
final testShoppingItem = ShoppingItem(
  id: '3b9d6c1a-2f4e-4a8b-9c0d-1e2f3a4b5c6d',
  name: 'Telur',
  quantity: 2,
  isDone: false,
  createdAt: DateTime.utc(2026, 10, 1, 8, 30),
  updatedAt: DateTime.utc(2026, 10, 1, 9),
);

/// Bentuk JSON `ShoppingItem` dari API untuk [testShoppingItem].
const shoppingItemJson = {
  'id': '3b9d6c1a-2f4e-4a8b-9c0d-1e2f3a4b5c6d',
  'name': 'Telur',
  'quantity': 2,
  'isDone': false,
  'createdAt': '2026-10-01T08:30:00.000Z',
  'updatedAt': '2026-10-01T09:00:00.000Z',
};

/// Barang ke-[i] untuk test daftar (id `item-<i>`, nama `Barang <i>`, jumlah [i]).
ShoppingItem shoppingItemNo(int i, {bool isDone = false}) => ShoppingItem(
  id: 'item-$i',
  name: 'Barang $i',
  quantity: i,
  isDone: isDone,
  createdAt: DateTime.utc(2026, 10, 1, 8, i),
  updatedAt: DateTime.utc(2026, 10, 1, 8, i),
);
