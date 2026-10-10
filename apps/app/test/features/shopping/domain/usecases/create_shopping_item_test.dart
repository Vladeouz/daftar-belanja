import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/create_shopping_item.dart';

import '../../mocks.dart';

void main() {
  late MockShoppingItemRepository repository;

  setUp(() => repository = MockShoppingItemRepository());

  void stubCreate(Result<ShoppingItem> result) => when(
    () => repository.create(
      name: any(named: 'name'),
      quantity: any(named: 'quantity'),
    ),
  ).thenAnswer((_) async => result);

  test('nama dirapikan, jumlah diteruskan', () async {
    stubCreate(Ok(testShoppingItem));

    final result = await CreateShoppingItem(repository)(
      name: '  Telur ',
      quantity: 2,
    );

    expect(result, Ok(testShoppingItem));
    verify(() => repository.create(name: 'Telur', quantity: 2)).called(1);
  });

  test('tanpa jumlah → quantity null (tidak dikirim)', () async {
    stubCreate(Ok(testShoppingItem));

    await CreateShoppingItem(repository)(name: 'Telur');

    verify(() => repository.create(name: 'Telur')).called(1);
  });

  test('nama sudah ada → Err(conflict) dari repository diteruskan', () async {
    const failure = Failure(FailureCode.conflict);
    stubCreate(const Err(failure));

    expect(
      await CreateShoppingItem(repository)(name: 'telur'),
      const Err<ShoppingItem>(failure),
    );
  });

  test('nama kosong tetap dikirim; Err validasi dari API diteruskan', () async {
    const failure = Failure(
      FailureCode.validation,
      fieldErrors: {
        'name': [FieldIssue('too_small', 'Too small')],
      },
    );
    stubCreate(const Err(failure));

    final result = await CreateShoppingItem(repository)(name: '   ');

    expect(result, const Err<ShoppingItem>(failure));
    verify(() => repository.create(name: '')).called(1);
  });
}
