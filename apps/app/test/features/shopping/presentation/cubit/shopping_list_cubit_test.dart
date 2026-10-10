import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_page.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_list_cubit.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_list_state.dart';

import '../../mocks.dart';

void main() {
  const all = ShoppingItemStatus.all;
  const open = ShoppingItemStatus.open;
  const done = ShoppingItemStatus.done;
  const offline = Failure(FailureCode.network);

  final open3 = shoppingItemNo(3);
  final done2 = shoppingItemNo(2, isDone: true);
  final open1 = shoppingItemNo(1);

  late MockListShoppingItems listItems;
  late MockUpdateShoppingItem updateItem;
  late MockClearDoneShoppingItems clearDone;

  setUp(() {
    listItems = MockListShoppingItems();
    updateItem = MockUpdateShoppingItem();
    clearDone = MockClearDoneShoppingItems();
  });

  ShoppingListCubit build() => ShoppingListCubit(
    listItems: listItems,
    updateItem: updateItem,
    clearDone: clearDone,
  );

  void stubList({
    ShoppingItemStatus? status,
    String? cursor,
    required Future<Result<ShoppingItemPage>> Function() answer,
  }) =>
      when(() => listItems(status: status, cursor: cursor))
          .thenAnswer((_) => answer());

  Future<Result<ShoppingItemPage>> ok(
    List<ShoppingItem> items, [
    String? nextCursor,
  ]) async => Ok(ShoppingItemPage(items: items, nextCursor: nextCursor));

  ShoppingListLoaded loaded(
    List<ShoppingItem> items, {
    ShoppingItemStatus filter = all,
    String? nextCursor,
    bool loadingMore = false,
    Failure? loadMoreFailure,
    Set<String> updatingIds = const {},
    bool clearing = false,
    Failure? actionFailure,
  }) => ShoppingListLoaded(
    filter,
    items: items,
    nextCursor: nextCursor,
    loadingMore: loadingMore,
    loadMoreFailure: loadMoreFailure,
    updatingIds: updatingIds,
    clearing: clearing,
    actionFailure: actionFailure,
  );

  ShoppingItem toggled(ShoppingItem item) => ShoppingItem(
    id: item.id,
    name: item.name,
    quantity: item.quantity,
    isDone: !item.isDone,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt.add(const Duration(minutes: 1)),
  );

  test('state awal: memuat filter Semua', () {
    expect(build().state, const ShoppingListLoading(all));
  });

  group('load (halaman pertama)', () {
    blocTest<ShoppingListCubit, ShoppingListState>(
      'berhasil → Loading lalu Loaded dengan nextCursor; filter dikirim',
      setUp: () => stubList(status: all, answer: () => ok([open3], 'c1')),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ShoppingListLoading(all),
        loaded([open3], nextCursor: 'c1'),
      ],
      verify: (_) => verify(() => listItems(status: all)).called(1),
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'error jaringan → LoadFailed; coba lagi → Loaded',
      setUp: () {
        var calls = 0;
        stubList(
          status: all,
          answer: () =>
              calls++ == 0 ? Future.value(const Err(offline)) : ok([open3]),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.load();
      },
      expect: () => [
        const ShoppingListLoading(all),
        const ShoppingListLoadFailed(all, offline),
        const ShoppingListLoading(all),
        loaded([open3]),
      ],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'load kedua saat halaman pertama masih dimuat diabaikan',
      setUp: () {
        final pending = Completer<Result<ShoppingItemPage>>();
        stubList(status: all, answer: () => pending.future);
        addTearDown(() => pending.complete(const Err(offline)));
      },
      build: build,
      act: (cubit) {
        unawaited(cubit.load());
        unawaited(cubit.load());
      },
      expect: () => const [ShoppingListLoading(all)],
      verify: (_) => verify(() => listItems(status: all)).called(1),
    );
  });

  group('setFilter', () {
    for (final (filter, items) in [
      (open, [open3, open1]),
      (done, [done2]),
      (all, [open3, done2, open1]),
    ]) {
      blocTest<ShoppingListCubit, ShoppingListState>(
        '${filter.name} → memuat ulang halaman pertama dengan status ${filter.name}',
        setUp: () => stubList(status: filter, answer: () => ok(items)),
        build: build,
        // Filter awal berbeda, agar setFilter tidak diabaikan.
        seed: () => loaded(const [], filter: filter == all ? open : all),
        act: (cubit) => cubit.setFilter(filter),
        expect: () => [
          ShoppingListLoading(filter),
          loaded(items, filter: filter),
        ],
        verify: (_) => verify(() => listItems(status: filter)).called(1),
      );
    }

    blocTest<ShoppingListCubit, ShoppingListState>(
      'filter yang sama diabaikan',
      build: build,
      seed: () => loaded([open3], filter: open),
      act: (cubit) => cubit.setFilter(open),
      expect: () => const <ShoppingListState>[],
      verify: (_) => verifyNever(
        () => listItems(
          status: any(named: 'status'),
          cursor: any(named: 'cursor'),
        ),
      ),
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'filter diganti sebelum hasil filter lama datang → hasil lama dibuang',
      setUp: () {
        final slow = Completer<Result<ShoppingItemPage>>();
        stubList(status: open, answer: () => slow.future);
        stubList(status: done, answer: () => ok([done2]));
        addTearDown(
          () => slow.complete(
            Ok(ShoppingItemPage(items: [open3], nextCursor: null)),
          ),
        );
      },
      build: build,
      seed: () => loaded(const []),
      act: (cubit) async {
        unawaited(cubit.setFilter(open));
        await cubit.setFilter(done);
      },
      expect: () => [
        const ShoppingListLoading(open),
        const ShoppingListLoading(done),
        loaded([done2], filter: done),
      ],
    );
  });

  group('loadMore (pagination)', () {
    blocTest<ShoppingListCubit, ShoppingListState>(
      'memakai nextCursor dan filter; halaman terakhir → hasMore false',
      setUp: () =>
          stubList(status: open, cursor: 'c1', answer: () => ok([open1])),
      build: build,
      seed: () => loaded([open3], filter: open, nextCursor: 'c1'),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        loaded([open3], filter: open, nextCursor: 'c1', loadingMore: true),
        loaded([open3, open1], filter: open),
      ],
      verify: (cubit) {
        verify(() => listItems(status: open, cursor: 'c1')).called(1);
        expect((cubit.state as ShoppingListLoaded).hasMore, isFalse);
      },
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'error jaringan → daftar tetap, loadMoreFailure terisi',
      setUp: () => stubList(
        status: all,
        cursor: 'c1',
        answer: () async => const Err(offline),
      ),
      build: build,
      seed: () => loaded([open3], nextCursor: 'c1'),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        loaded([open3], nextCursor: 'c1', loadingMore: true),
        loaded([open3], nextCursor: 'c1', loadMoreFailure: offline),
      ],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'halaman terakhir atau sedang memuat → diabaikan',
      build: build,
      seed: () => loaded([open3]),
      act: (cubit) => cubit.loadMore(),
      expect: () => const <ShoppingListState>[],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'filter diganti selama halaman berikutnya dimuat → hasilnya dibuang',
      setUp: () {
        final slow = Completer<Result<ShoppingItemPage>>();
        stubList(status: all, cursor: 'c1', answer: () => slow.future);
        stubList(status: done, answer: () => ok([done2]));
        addTearDown(
          () => slow.complete(
            Ok(ShoppingItemPage(items: [open1], nextCursor: null)),
          ),
        );
      },
      build: build,
      seed: () => loaded([open3], nextCursor: 'c1'),
      act: (cubit) async {
        unawaited(cubit.loadMore());
        await cubit.setFilter(done);
      },
      expect: () => [
        loaded([open3], nextCursor: 'c1', loadingMore: true),
        const ShoppingListLoading(done),
        loaded([done2], filter: done),
      ],
    );
  });

  group('toggleDone', () {
    blocTest<ShoppingListCubit, ShoppingListState>(
      'filter Semua: status tersimpan lewat UpdateShoppingItem(isDone), barang tetap di tempatnya',
      setUp: () =>
          when(() => updateItem(open3.id, isDone: true))
              .thenAnswer((_) async => Ok(toggled(open3))),
      build: build,
      seed: () => loaded([open3, open1]),
      act: (cubit) => cubit.toggleDone(open3),
      expect: () => [
        loaded([open3, open1], updatingIds: {open3.id}),
        loaded([toggled(open3), open1]),
      ],
      verify: (_) => verify(() => updateItem(open3.id, isDone: true)).called(1),
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'sudah dibeli → ditandai belum (isDone false dikirim)',
      setUp: () =>
          when(() => updateItem(done2.id, isDone: false))
              .thenAnswer((_) async => Ok(toggled(done2))),
      build: build,
      seed: () => loaded([done2]),
      act: (cubit) => cubit.toggleDone(done2),
      skip: 1,
      expect: () => [
        loaded([toggled(done2)]),
      ],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'filter Belum: barang yang ditandai sudah dibeli hilang dari daftar',
      setUp: () =>
          when(() => updateItem(open3.id, isDone: true))
              .thenAnswer((_) async => Ok(toggled(open3))),
      build: build,
      seed: () => loaded([open3, open1], filter: open),
      act: (cubit) => cubit.toggleDone(open3),
      skip: 1,
      expect: () => [
        loaded([open1], filter: open),
      ],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'gagal → daftar tetap, actionFailure terisi',
      setUp: () =>
          when(() => updateItem(open3.id, isDone: true))
              .thenAnswer((_) async => const Err(offline)),
      build: build,
      seed: () => loaded([open3]),
      act: (cubit) => cubit.toggleDone(open3),
      expect: () => [
        loaded([open3], updatingIds: {open3.id}),
        loaded([open3], actionFailure: offline),
      ],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'aksi baru mengosongkan actionFailure lama',
      setUp: () =>
          when(() => updateItem(open3.id, isDone: true))
              .thenAnswer((_) async => const Err(offline)),
      build: build,
      seed: () => loaded([open3], actionFailure: offline),
      act: (cubit) => cubit.toggleDone(open3),
      expect: () => [
        loaded([open3], updatingIds: {open3.id}),
        loaded([open3], actionFailure: offline),
      ],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'barang yang statusnya masih disimpan → diabaikan',
      build: build,
      seed: () => loaded([open3], updatingIds: {open3.id}),
      act: (cubit) => cubit.toggleDone(open3),
      expect: () => const <ShoppingListState>[],
      verify: (_) =>
          verifyNever(() => updateItem(any(), isDone: any(named: 'isDone'))),
    );
  });

  group('clearDone', () {
    blocTest<ShoppingListCubit, ShoppingListState>(
      'berhasil → barang yang sudah dibeli hilang, cursor tetap',
      setUp: () => when(() => clearDone()).thenAnswer((_) async => const Ok(1)),
      build: build,
      seed: () => loaded([open3, done2, open1], nextCursor: 'c1'),
      act: (cubit) => cubit.clearDone(),
      expect: () => [
        loaded([open3, done2, open1], nextCursor: 'c1', clearing: true),
        loaded([open3, open1], nextCursor: 'c1'),
      ],
      verify: (_) => verify(() => clearDone()).called(1),
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'filter Sudah → daftar kosong',
      setUp: () => when(() => clearDone()).thenAnswer((_) async => const Ok(1)),
      build: build,
      seed: () => loaded([done2], filter: done),
      act: (cubit) => cubit.clearDone(),
      skip: 1,
      expect: () => [loaded(const [], filter: done)],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'gagal → daftar tetap, actionFailure terisi',
      setUp: () =>
          when(() => clearDone()).thenAnswer((_) async => const Err(offline)),
      build: build,
      seed: () => loaded([done2]),
      act: (cubit) => cubit.clearDone(),
      expect: () => [
        loaded([done2], clearing: true),
        loaded([done2], actionFailure: offline),
      ],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'sedang berjalan atau daftar belum tampil → diabaikan',
      build: build,
      seed: () => loaded([done2], clearing: true),
      act: (cubit) => cubit.clearDone(),
      expect: () => const <ShoppingListState>[],
      verify: (_) => verifyNever(() => clearDone()),
    );
  });

  group('hasil form', () {
    final saved1 = ShoppingItem(
      id: open1.id,
      name: 'Diubah',
      quantity: 5,
      isDone: false,
      createdAt: open1.createdAt,
      updatedAt: open1.updatedAt,
    );
    final newItem = shoppingItemNo(9);

    blocTest<ShoppingListCubit, ShoppingListState>(
      'itemSaved: barang lama diganti di tempatnya',
      build: build,
      seed: () => loaded([open3, open1]),
      act: (cubit) => cubit.itemSaved(saved1),
      expect: () => [
        loaded([open3, saved1]),
      ],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'itemSaved: barang baru di paling atas',
      build: build,
      seed: () => loaded([open3]),
      act: (cubit) => cubit.itemSaved(newItem),
      expect: () => [
        loaded([newItem, open3]),
      ],
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'itemSaved: barang baru (belum dibeli) tidak masuk filter Sudah',
      build: build,
      seed: () => loaded([done2], filter: done),
      act: (cubit) => cubit.itemSaved(newItem),
      // State sama tidak dipancarkan ulang.
      expect: () => const <ShoppingListState>[],
      verify: (cubit) => expect(cubit.state, loaded([done2], filter: done)),
    );

    blocTest<ShoppingListCubit, ShoppingListState>(
      'itemDeleted: barang hilang dari daftar',
      build: build,
      seed: () => loaded([open3, open1]),
      act: (cubit) => cubit.itemDeleted(open3.id),
      expect: () => [
        loaded([open1]),
      ],
    );
  });
}
