import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_cubit.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_state.dart';
import 'package:app/features/shopping/presentation/pages/shopping_item_form_page.dart';

import '../../mocks.dart';

void main() {
  const nameKey = 'shopping-item-name';
  const quantityKey = 'shopping-item-quantity';
  final item = testShoppingItem;

  late MockShoppingItemFormCubit cubit;

  setUp(() {
    cubit = MockShoppingItemFormCubit();
    when(
      () => cubit.save(
        name: any(named: 'name'),
        quantity: any(named: 'quantity'),
      ),
    ).thenAnswer((_) async {});
    when(() => cubit.delete()).thenAnswer((_) async {});
  });

  /// Halaman form di atas halaman "daftar" sederhana, agar `context.pop(state)` bisa diuji.
  /// Nilai yang dikembalikan halaman form ditampung di list hasil.
  Future<List<Object?>> pumpPage(
    WidgetTester tester,
    ShoppingItemFormState state, {
    Stream<ShoppingItemFormState> stream = const Stream.empty(),
  }) async {
    whenListen(cubit, stream, initialState: state);
    final results = <Object?>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  results.add(await context.push<Object?>('/form')),
              child: const Text('buka form'),
            ),
          ),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, _) => BlocProvider<ShoppingItemFormCubit>.value(
                value: cubit,
                child: const ShoppingItemFormPage(),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('buka form'));
    // Bukan pumpAndSettle: indikator saat menyimpan beranimasi terus.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return results;
  }

  TextField fieldOf(WidgetTester tester, String key) =>
      tester.widget<TextField>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(TextField),
        ),
      );

  Finder saveButton() => find.widgetWithText(FilledButton, 'Simpan');

  testWidgets('barang baru: judul, jumlah awal 1, tanpa tombol hapus', (
    tester,
  ) async {
    await pumpPage(tester, const ShoppingItemFormEditing());

    expect(find.text('Tambah barang'), findsOneWidget);
    expect(fieldOf(tester, quantityKey).controller!.text, '1');
    expect(find.byTooltip('Hapus'), findsNothing);

    await tester.enterText(find.byKey(const Key(nameKey)), 'Telur');
    await tester.enterText(find.byKey(const Key(quantityKey)), '12');
    await tester.tap(saveButton());

    verify(() => cubit.save(name: 'Telur', quantity: 12)).called(1);
  });

  testWidgets('jumlah dikosongkan → quantity null', (tester) async {
    await pumpPage(tester, const ShoppingItemFormEditing());

    await tester.enterText(find.byKey(const Key(nameKey)), 'Telur');
    await tester.enterText(find.byKey(const Key(quantityKey)), '');
    await tester.tap(saveButton());

    verify(() => cubit.save(name: 'Telur')).called(1);
  });

  testWidgets('jumlah hanya menerima angka, paling banyak 3 digit', (
    tester,
  ) async {
    await pumpPage(tester, const ShoppingItemFormEditing());

    await tester.enterText(find.byKey(const Key(quantityKey)), '1a2b34');

    expect(fieldOf(tester, quantityKey).controller!.text, '123');
  });

  testWidgets('ubah barang: field terisi dari barang, simpan mengirim isian', (
    tester,
  ) async {
    await pumpPage(tester, ShoppingItemFormEditing(item: item));

    expect(find.text('Ubah barang'), findsOneWidget);
    expect(fieldOf(tester, nameKey).controller!.text, item.name);
    expect(fieldOf(tester, quantityKey).controller!.text, '${item.quantity}');

    await tester.tap(saveButton());
    verify(() => cubit.save(name: item.name, quantity: item.quantity))
        .called(1);
  });

  group('error', () {
    testWidgets('nama kosong → "Wajib diisi." di field nama, tidak dikirim', (
      tester,
    ) async {
      await pumpPage(tester, const ShoppingItemFormEditing());

      await tester.enterText(find.byKey(const Key(nameKey)), '   ');
      await tester.tap(saveButton());
      await tester.pump();

      expect(fieldOf(tester, nameKey).decoration!.errorText, 'Wajib diisi.');
      verifyNever(
        () => cubit.save(
          name: any(named: 'name'),
          quantity: any(named: 'quantity'),
        ),
      );
    });

    testWidgets(
      'nama sudah ada (CONFLICT) → "Barang ini sudah ada di daftar." di field nama',
      (tester) async {
        await pumpPage(
          tester,
          const ShoppingItemFormEditing(
            failure: Failure(
              FailureCode.conflict,
              message: 'Shopping item name already exists',
            ),
          ),
        );

        expect(
          fieldOf(tester, nameKey).decoration!.errorText,
          'Barang ini sudah ada di daftar.',
        );
        expect(fieldOf(tester, quantityKey).decoration!.errorText, isNull);
        // Pesan umum CONFLICT dan pesan Inggris dari server tidak ditampilkan.
        expect(
          find.text('Data bertentangan dengan data yang sudah ada.'),
          findsNothing,
        );
        expect(find.text('Shopping item name already exists'), findsNothing);
      },
    );

    testWidgets('error validasi API pada quantity → tampil di field jumlah', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const ShoppingItemFormEditing(
          failure: Failure(
            FailureCode.validation,
            fieldErrors: {
              'quantity': [FieldIssue('too_small', 'Too small')],
            },
          ),
        ),
      );

      expect(
        fieldOf(tester, quantityKey).decoration!.errorText,
        'Terlalu pendek.',
      );
      expect(fieldOf(tester, nameKey).decoration!.errorText, isNull);
      expect(find.text('Periksa kembali isian Anda.'), findsNothing);
    });

    testWidgets('error validasi API pada name → tampil di field nama', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const ShoppingItemFormEditing(
          failure: Failure(
            FailureCode.validation,
            fieldErrors: {
              'name': [FieldIssue('too_big', 'Too big')],
            },
          ),
        ),
      );

      expect(
        fieldOf(tester, nameKey).decoration!.errorText,
        'Terlalu panjang.',
      );
    });

    testWidgets('error jaringan saat menyimpan → pesan di atas tombol simpan', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const ShoppingItemFormEditing(failure: Failure(FailureCode.network)),
      );

      expect(
        find.text('Tidak dapat terhubung ke server. Periksa koneksi Anda.'),
        findsOneWidget,
      );
      expect(fieldOf(tester, nameKey).decoration!.errorText, isNull);
    });
  });

  testWidgets('saat menyimpan: tombol dan field nonaktif, indikator tampil', (
    tester,
  ) async {
    await pumpPage(
      tester,
      ShoppingItemFormEditing(
        item: item,
        status: ShoppingItemFormStatus.saving,
      ),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.delete_outline),
          )
          .onPressed,
      isNull,
    );
    expect(fieldOf(tester, nameKey).enabled, isFalse);
    expect(fieldOf(tester, quantityKey).enabled, isFalse);
  });

  group('hapus', () {
    testWidgets('konfirmasi "Hapus" → cubit.delete()', (tester) async {
      await pumpPage(tester, ShoppingItemFormEditing(item: item));

      await tester.tap(find.byTooltip('Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus barang?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      verify(() => cubit.delete()).called(1);
    });

    testWidgets('"Batal" → tidak menghapus', (tester) async {
      await pumpPage(tester, ShoppingItemFormEditing(item: item));

      await tester.tap(find.byTooltip('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus barang?'), findsNothing);
      verifyNever(() => cubit.delete());
    });
  });

  group('selesai → halaman ditutup membawa hasil', () {
    testWidgets('Saved', (tester) async {
      final results = await pumpPage(
        tester,
        const ShoppingItemFormEditing(),
        stream: Stream.value(ShoppingItemFormSaved(item)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingItemFormPage), findsNothing);
      expect(results, [ShoppingItemFormSaved(item)]);
    });

    testWidgets('Deleted', (tester) async {
      final results = await pumpPage(
        tester,
        ShoppingItemFormEditing(item: item),
        stream: Stream.value(ShoppingItemFormDeleted(item.id)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingItemFormPage), findsNothing);
      expect(results, [ShoppingItemFormDeleted(item.id)]);
    });
  });
}
