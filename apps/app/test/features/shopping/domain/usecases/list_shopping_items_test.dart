import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_page.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';
import 'package:app/features/shopping/domain/usecases/list_shopping_items.dart';

import '../../mocks.dart';

void main() {
  late MockShoppingItemRepository repository;

  setUp(() => repository = MockShoppingItemRepository());

  void stubList(Result<ShoppingItemPage> result) => when(
    () => repository.list(
      status: any(named: 'status'),
      cursor: any(named: 'cursor'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) async => result);

  test(
    'halaman pertama tanpa status, cursor, dan limit (bawaan API)',
    () async {
      final page = ShoppingItemPage(
        items: [testShoppingItem],
        nextCursor: 'c1',
      );
      stubList(Ok(page));

      expect(await ListShoppingItems(repository)(), Ok(page));
      verify(() => repository.list()).called(1);
    },
  );

  test('meneruskan status, cursor, dan limit', () async {
    const page = ShoppingItemPage(items: [], nextCursor: null);
    stubList(const Ok(page));

    await ListShoppingItems(repository)(
      status: ShoppingItemStatus.done,
      cursor: 'c1',
      limit: 10,
    );

    verify(
      () => repository.list(
        status: ShoppingItemStatus.done,
        cursor: 'c1',
        limit: 10,
      ),
    ).called(1);
  });

  test('mengembalikan Err dari repository', () async {
    const failure = Failure(FailureCode.network);
    stubList(const Err(failure));

    expect(
      await ListShoppingItems(repository)(),
      const Err<ShoppingItemPage>(failure),
    );
  });
}
