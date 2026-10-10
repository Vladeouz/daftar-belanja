import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/update_shopping_item.dart';

import '../../mocks.dart';

void main() {
  late MockShoppingItemRepository repository;

  setUp(() => repository = MockShoppingItemRepository());

  void stubUpdate(Result<ShoppingItem> result) => when(
    () => repository.update(
      any(),
      name: any(named: 'name'),
      quantity: any(named: 'quantity'),
      isDone: any(named: 'isDone'),
    ),
  ).thenAnswer((_) async => result);

  test('nama dirapikan, jumlah dan status diteruskan', () async {
    stubUpdate(Ok(testShoppingItem));

    final result = await UpdateShoppingItem(repository)(
      testShoppingItem.id,
      name: ' Telur  ',
      quantity: 2,
      isDone: false,
    );

    expect(result, Ok(testShoppingItem));
    verify(
      () => repository.update(
        testShoppingItem.id,
        name: 'Telur',
        quantity: 2,
        isDone: false,
      ),
    ).called(1);
  });

  test('hanya status → nama dan jumlah null (tidak diubah)', () async {
    stubUpdate(Ok(testShoppingItem));

    await UpdateShoppingItem(repository)(testShoppingItem.id, isDone: true);

    verify(() => repository.update(testShoppingItem.id, isDone: true))
        .called(1);
  });

  test('nama sudah dipakai barang lain → Err(conflict) diteruskan', () async {
    const failure = Failure(FailureCode.conflict);
    stubUpdate(const Err(failure));

    expect(
      await UpdateShoppingItem(repository)(testShoppingItem.id, name: 'Susu'),
      const Err<ShoppingItem>(failure),
    );
  });

  test('mengembalikan Err notFound dari repository', () async {
    const failure = Failure(FailureCode.notFound);
    stubUpdate(const Err(failure));

    expect(
      await UpdateShoppingItem(repository)('lain', isDone: true),
      const Err<ShoppingItem>(failure),
    );
  });
}
