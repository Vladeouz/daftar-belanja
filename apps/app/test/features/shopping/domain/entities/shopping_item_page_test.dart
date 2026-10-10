import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/shopping/domain/entities/shopping_item_page.dart';

import '../../mocks.dart';

void main() {
  test('hasMore mengikuti nextCursor', () {
    expect(
      ShoppingItemPage(items: [testShoppingItem], nextCursor: 'c1').hasMore,
      isTrue,
    );
    expect(
      const ShoppingItemPage(items: [], nextCursor: null).hasMore,
      isFalse,
    );
  });

  test('sama bila isi dan cursor sama', () {
    expect(
      ShoppingItemPage(items: [testShoppingItem], nextCursor: 'c1'),
      ShoppingItemPage(items: [testShoppingItem], nextCursor: 'c1'),
    );
  });
}
