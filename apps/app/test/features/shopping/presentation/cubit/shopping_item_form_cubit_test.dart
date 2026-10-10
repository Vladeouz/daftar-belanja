import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_cubit.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_state.dart';

import '../../mocks.dart';

void main() {
  const conflict = Failure(
    FailureCode.conflict,
    message: 'Shopping item name already exists',
  );
  const offline = Failure(FailureCode.network);
  final item = testShoppingItem;

  late MockCreateShoppingItem createItem;
  late MockUpdateShoppingItem updateItem;
  late MockDeleteShoppingItem deleteItem;

  setUp(() {
    createItem = MockCreateShoppingItem();
    updateItem = MockUpdateShoppingItem();
    deleteItem = MockDeleteShoppingItem();
  });

  ShoppingItemFormCubit build() => ShoppingItemFormCubit(
    createItem: createItem,
    updateItem: updateItem,
    deleteItem: deleteItem,
  );

  test('state awal: form barang baru', () {
    expect(build().state, const ShoppingItemFormEditing());
  });

  blocTest<ShoppingItemFormCubit, ShoppingItemFormState>(
    'edit → form berisi barang',
    build: build,
    act: (cubit) => cubit.edit(item),
    expect: () => [ShoppingItemFormEditing(item: item)],
  );

  group('save barang baru', () {
    blocTest<ShoppingItemFormCubit, ShoppingItemFormState>(
      'berhasil → saving lalu Saved; nama dan jumlah dikirim',
      setUp: () =>
          when(() => createItem(name: 'Telur', quantity: 2))
              .thenAnswer((_) async => Ok(item)),
      build: build,
      act: (cubit) => cubit.save(name: 'Telur', quantity: 2),
      expect: () => [
        const ShoppingItemFormEditing(status: ShoppingItemFormStatus.saving),
        ShoppingItemFormSaved(item),
      ],
      verify: (_) =>
          verify(() => createItem(name: 'Telur', quantity: 2)).called(1),
    );

    blocTest<ShoppingItemFormCubit, ShoppingItemFormState>(
      'jumlah kosong → quantity null (bawaan API)',
      setUp: () =>
          when(() => createItem(name: 'Telur'))
              .thenAnswer((_) async => Ok(item)),
      build: build,
      act: (cubit) => cubit.save(name: 'Telur'),
      skip: 1,
      expect: () => [ShoppingItemFormSaved(item)],
      verify: (_) => verify(() => createItem(name: 'Telur')).called(1),
    );

    blocTest<ShoppingItemFormCubit, ShoppingItemFormState>(
      'nama sudah ada (CONFLICT) → kembali ke form dengan failure conflict',
      setUp: () =>
          when(() => createItem(name: 'telur', quantity: 1))
              .thenAnswer((_) async => const Err(conflict)),
      build: build,
      act: (cubit) => cubit.save(name: 'telur', quantity: 1),
      expect: () => const [
        ShoppingItemFormEditing(status: ShoppingItemFormStatus.saving),
        ShoppingItemFormEditing(failure: conflict),
      ],
    );

    blocTest<ShoppingItemFormCubit, ShoppingItemFormState>(
      'simpan kedua saat masih menyimpan diabaikan',
      setUp: () {
        final pending = Completer<Result<ShoppingItem>>();
        when(
          () => createItem(
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
          ),
        ).thenAnswer((_) => pending.future);
        addTearDown(() => pending.complete(const Err(offline)));
      },
      build: build,
      act: (cubit) {
        unawaited(cubit.save(name: 'Telur'));
        unawaited(cubit.save(name: 'Telur'));
      },
      expect: () => const [
        ShoppingItemFormEditing(status: ShoppingItemFormStatus.saving),
      ],
      verify: (_) => verify(
        () => createItem(
          name: any(named: 'name'),
          quantity: any(named: 'quantity'),
        ),
      ).called(1),
    );
  });

  group('save barang yang ada', () {
    blocTest<ShoppingItemFormCubit, ShoppingItemFormState>(
      'berhasil → UpdateShoppingItem dengan nama dan jumlah, tanpa isDone',
      setUp: () =>
          when(() => updateItem(item.id, name: 'Telur ayam', quantity: 3))
              .thenAnswer((_) async => Ok(item)),
      build: build,
      seed: () => ShoppingItemFormEditing(item: item),
      act: (cubit) => cubit.save(name: 'Telur ayam', quantity: 3),
      expect: () => [
        ShoppingItemFormEditing(
          item: item,
          status: ShoppingItemFormStatus.saving,
        ),
        ShoppingItemFormSaved(item),
      ],
      verify: (_) {
        verify(() => updateItem(item.id, name: 'Telur ayam', quantity: 3))
            .called(1);
        verifyNoMoreInteractions(createItem);
      },
    );

    blocTest<ShoppingItemFormCubit, ShoppingItemFormState>(
      'nama barang lain (CONFLICT) → form tetap berisi barang, failure conflict',
      setUp: () =>
          when(() => updateItem(item.id, name: 'Susu', quantity: 2))
              .thenAnswer((_) async => const Err(conflict)),
      build: build,
      seed: () => ShoppingItemFormEditing(item: item),
      act: (cubit) => cubit.save(name: 'Susu', quantity: 2),
      skip: 1,
      expect: () => [ShoppingItemFormEditing(item: item, failure: conflict)],
    );
  });

  group('delete', () {
    blocTest<ShoppingItemFormCubit, ShoppingItemFormState>(
      'berhasil → deleting lalu Deleted(id)',
      setUp: () =>
          when(() => deleteItem(item.id))
              .thenAnswer((_) async => const Ok(null)),
      build: build,
      seed: () => ShoppingItemFormEditing(item: item),
      act: (cubit) => cubit.delete(),
      expect: () => [
        ShoppingItemFormEditing(
          item: item,
          status: ShoppingItemFormStatus.deleting,
        ),
        ShoppingItemFormDeleted(item.id),
      ],
    );

    blocTest<ShoppingItemFormCubit, ShoppingItemFormState>(
      'gagal → kembali ke form dengan failure',
      setUp: () =>
          when(() => deleteItem(item.id))
              .thenAnswer((_) async => const Err(offline)),
      build: build,
      seed: () => ShoppingItemFormEditing(item: item),
      act: (cubit) => cubit.delete(),
      skip: 1,
      expect: () => [ShoppingItemFormEditing(item: item, failure: offline)],
    );

    blocTest<ShoppingItemFormCubit, ShoppingItemFormState>(
      'barang baru → diabaikan',
      build: build,
      act: (cubit) => cubit.delete(),
      expect: () => const <ShoppingItemFormState>[],
      verify: (_) => verifyNever(() => deleteItem(any())),
    );
  });
}
