import 'package:mocktail/mocktail.dart';

import 'package:app/features/shopping/data/shopping_item_remote_data_source.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';

class MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class MockShoppingItemRemoteDataSource extends Mock
    implements ShoppingItemRemoteDataSource {}

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
