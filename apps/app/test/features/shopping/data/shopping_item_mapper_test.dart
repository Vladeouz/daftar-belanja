import 'package:api_client/api_client.dart' as dto;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/shopping/data/shopping_item_mapper.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_page.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';

import '../mocks.dart';

void main() {
  test('shoppingItemFromDto memetakan semua field dengan timestamp UTC', () {
    final item = shoppingItemFromDto(
      dto.ShoppingItem.fromJson(shoppingItemJson),
    );

    expect(item, testShoppingItem);
    expect(item.createdAt.isUtc, isTrue);
    expect(item.updatedAt.isUtc, isTrue);
  });

  test('isDone true ikut terpetakan', () {
    final item = shoppingItemFromDto(
      dto.ShoppingItem.fromJson({...shoppingItemJson, 'isDone': true}),
    );

    expect(item.isDone, isTrue);
  });

  test('shoppingItemPageFromDto memetakan items dan nextCursor', () {
    final page = shoppingItemPageFromDto(
      dto.ShoppingItemPage.fromJson({
        'items': [shoppingItemJson, shoppingItemJson],
        'nextCursor': 'c1',
      }),
    );

    expect(
      page,
      ShoppingItemPage(
        items: [testShoppingItem, testShoppingItem],
        nextCursor: 'c1',
      ),
    );
  });

  test('halaman terakhir → nextCursor null, items tidak bisa diubah', () {
    final page = shoppingItemPageFromDto(
      dto.ShoppingItemPage.fromJson({'items': <Object?>[], 'nextCursor': null}),
    );

    expect(page.nextCursor, isNull);
    expect(page.hasMore, isFalse);
    expect(() => page.items.add(testShoppingItem), throwsUnsupportedError);
  });

  test('setiap filter status punya nilai kontrak dengan nama sama', () {
    for (final status in ShoppingItemStatus.values) {
      expect(shoppingItemStatusToDto(status).json, status.name);
    }
  });
}
