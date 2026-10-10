import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_list_cubit.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_list_state.dart';
import 'package:app/features/shopping/presentation/pages/shopping_page.dart';

import '../../mocks.dart';

void main() {
  const all = ShoppingItemStatus.all;
  const offline = Failure(FailureCode.network);
  const offlineMessage =
      'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
  final open1 = shoppingItemNo(1);
  final done2 = shoppingItemNo(2, isDone: true);

  late MockShoppingListCubit cubit;

  setUpAll(() {
    registerFallbackValue(open1);
    registerFallbackValue(all);
  });

  setUp(() {
    cubit = MockShoppingListCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.loadMore()).thenAnswer((_) async {});
    when(() => cubit.setFilter(any())).thenAnswer((_) async {});
    when(() => cubit.toggleDone(any())).thenAnswer((_) async {});
    when(() => cubit.clearDone()).thenAnswer((_) async {});
  });

  Future<void> pumpPage(
    WidgetTester tester,
    ShoppingListState state, {
    Stream<ShoppingListState> stream = const Stream.empty(),
  }) async {
    whenListen(cubit, stream, initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ShoppingListCubit>.value(
          value: cubit,
          child: const ShoppingPage(),
        ),
      ),
    );
    await tester.pump();
  }

  ShoppingListLoaded loaded(
    List<ShoppingItem> items, {
    ShoppingItemStatus filter = all,
    String? nextCursor,
    Set<String> updatingIds = const {},
    bool clearing = false,
    Failure? actionFailure,
  }) => ShoppingListLoaded(
    filter,
    items: items,
    nextCursor: nextCursor,
    updatingIds: updatingIds,
    clearing: clearing,
    actionFailure: actionFailure,
  );

  Checkbox checkboxOf(WidgetTester tester, String name) =>
      tester.widget<Checkbox>(
        find.descendant(
          of: find.widgetWithText(ListTile, name),
          matching: find.byType(Checkbox),
        ),
      );

  Set<ShoppingItemStatus> selectedFilter(WidgetTester tester) => tester
      .widget<SegmentedButton<ShoppingItemStatus>>(
        find.byType(SegmentedButton<ShoppingItemStatus>),
      )
      .selected;

  testWidgets('memuat halaman pertama → indikator, filter tetap tampil', (
    tester,
  ) async {
    await pumpPage(tester, const ShoppingListLoading(ShoppingItemStatus.done));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(selectedFilter(tester), {ShoppingItemStatus.done});
  });

  testWidgets('API mati → pesan jaringan dan "Coba lagi" memuat ulang', (
    tester,
  ) async {
    await pumpPage(tester, const ShoppingListLoadFailed(all, offline));

    expect(find.text(offlineMessage), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Coba lagi'));

    verify(() => cubit.load()).called(1);
  });

  for (final (filter, message) in [
    (ShoppingItemStatus.all, 'Daftar belanja masih kosong.'),
    (ShoppingItemStatus.open, 'Tidak ada barang yang belum dibeli.'),
    (ShoppingItemStatus.done, 'Belum ada barang yang sudah dibeli.'),
  ]) {
    testWidgets('daftar kosong (${filter.name}) → "$message"', (tester) async {
      await pumpPage(tester, loaded(const [], filter: filter));

      expect(find.text(message), findsOneWidget);
    });
  }

  testWidgets('menampilkan nama, jumlah, dan status; sudah dibeli dicoret', (
    tester,
  ) async {
    await pumpPage(tester, loaded([open1, done2]));

    expect(find.text('Daftar belanja'), findsOneWidget);
    expect(find.text('Barang 1'), findsOneWidget);
    expect(find.text('× 1'), findsOneWidget);
    expect(find.text('× 2'), findsOneWidget);
    expect(checkboxOf(tester, 'Barang 1').value, isFalse);
    expect(checkboxOf(tester, 'Barang 2').value, isTrue);
    expect(
      tester.widget<Text>(find.text('Barang 2')).style?.decoration,
      TextDecoration.lineThrough,
    );
    expect(tester.widget<Text>(find.text('Barang 1')).style, isNull);
    expect(find.byTooltip('Tambah barang'), findsOneWidget);
  });

  testWidgets('filter Semua, Belum, Sudah → setFilter dengan status itu', (
    tester,
  ) async {
    await pumpPage(tester, loaded([open1]));
    expect(selectedFilter(tester), {all});

    await tester.tap(find.text('Belum'));
    await tester.tap(find.text('Sudah'));
    await tester.pump();

    verifyInOrder([
      () => cubit.setFilter(ShoppingItemStatus.open),
      () => cubit.setFilter(ShoppingItemStatus.done),
    ]);
  });

  testWidgets('checkbox ditekan → toggleDone(barang itu)', (tester) async {
    await pumpPage(tester, loaded([open1, done2]));

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Barang 2'),
        matching: find.byType(Checkbox),
      ),
    );

    verify(() => cubit.toggleDone(done2)).called(1);
  });

  testWidgets('status barang sedang disimpan → checkbox nonaktif', (
    tester,
  ) async {
    await pumpPage(tester, loaded([open1, done2], updatingIds: {open1.id}));

    expect(checkboxOf(tester, 'Barang 1').onChanged, isNull);
    expect(checkboxOf(tester, 'Barang 2').onChanged, isNotNull);
  });

  group('hapus yang sudah dibeli', () {
    testWidgets('dikonfirmasi → clearDone()', (tester) async {
      await pumpPage(tester, loaded([open1, done2]));

      await tester.tap(find.byTooltip('Hapus yang sudah dibeli'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus yang sudah dibeli?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      verify(() => cubit.clearDone()).called(1);
    });

    testWidgets('"Batal" → tidak menghapus', (tester) async {
      await pumpPage(tester, loaded([done2]));

      await tester.tap(find.byTooltip('Hapus yang sudah dibeli'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.clearDone());
    });

    testWidgets('sedang berjalan → tombol nonaktif, indikator tampil', (
      tester,
    ) async {
      await pumpPage(tester, loaded([done2], clearing: true));

      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove_done),
      );
      expect(button.onPressed, isNull);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  testWidgets('aksi gagal → SnackBar berisi pesan kegagalan', (tester) async {
    await pumpPage(
      tester,
      loaded([open1]),
      stream: Stream.value(loaded([open1], actionFailure: offline)),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(offlineMessage),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'masih ada halaman berikutnya → loadMore saat baris akhir tampil',
    (tester) async {
      await pumpPage(tester, loaded([open1], nextCursor: 'c1'));

      verify(() => cubit.loadMore()).called(1);
    },
  );
}
