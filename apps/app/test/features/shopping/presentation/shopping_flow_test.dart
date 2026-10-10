import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:app/app.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/features/auth/auth_dependencies.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';
import 'package:app/features/shopping/presentation/pages/shopping_item_form_page.dart';
import 'package:app/features/shopping/presentation/pages/shopping_page.dart';
import 'package:app/features/shopping/shopping_dependencies.dart';

import '../../auth/fake_auth_repository.dart';
import '../fake_shopping_item_repository.dart';

/// Alur fitur shopping (FR-05) lewat router, Cubit, dan use case asli; hanya repository yang
/// palsu ([FakeShoppingItemRepository] meniru API).
void main() {
  late GetIt container;
  late FakeShoppingItemRepository shopping;

  void setUpShopping({int initialCount = 0, Set<int> doneNumbers = const {}}) {
    shopping = FakeShoppingItemRepository(
      initialCount: initialCount,
      doneNumbers: doneNumbers,
    );
    container = GetIt.asNewInstance();
    registerAuthDependencies(container);
    registerShoppingDependencies(container);
    container
      ..unregister<AuthRepository>()
      ..registerSingleton<AuthRepository>(
        FakeAuthRepository(
          signedIn: FakeAuthRepository.userFor('a@example.com'),
        ),
      )
      ..unregister<ShoppingItemRepository>()
      ..registerSingleton<ShoppingItemRepository>(shopping);
    addTearDown(container.reset);
  }

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String initialLocation = AppRoutes.home,
  }) async {
    final router = createRouter(
      container: container,
      initialLocation: initialLocation,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(App(router: router));
    await tester.pumpAndSettle();
    return router;
  }

  String pathOf(GoRouter router) =>
      router.routeInformationProvider.value.uri.path;

  /// Nama barang di daftar, dari atas ke bawah.
  List<String?> names(WidgetTester tester) => tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((tile) => (tile.title! as Text).data)
      .toList();

  Checkbox checkboxOf(WidgetTester tester, String name) =>
      tester.widget<Checkbox>(
        find.descendant(
          of: find.widgetWithText(ListTile, name),
          matching: find.byType(Checkbox),
        ),
      );

  Future<void> tapFilter(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> reload(WidgetTester tester, GoRouter router) async {
    router.go('/tidak-ada');
    await tester.pumpAndSettle();
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();
  }

  testWidgets('sudah login → daftar belanja tampil sebagai halaman utama', (
    tester,
  ) async {
    setUpShopping(initialCount: 1);
    final router = await pumpApp(tester);

    expect(find.byType(ShoppingPage), findsOneWidget);
    expect(find.text('Daftar belanja'), findsOneWidget);
    expect(pathOf(router), AppRoutes.shopping);
    expect(names(tester), ['Barang 1']);
  });

  testWidgets('filter Semua, Belum, Sudah → isi daftar sesuai filter', (
    tester,
  ) async {
    setUpShopping(initialCount: 4, doneNumbers: {2, 3});
    await pumpApp(tester);

    expect(names(tester), ['Barang 4', 'Barang 3', 'Barang 2', 'Barang 1']);

    await tapFilter(tester, 'Belum');
    expect(names(tester), ['Barang 4', 'Barang 1']);

    await tapFilter(tester, 'Sudah');
    expect(names(tester), ['Barang 3', 'Barang 2']);

    await tapFilter(tester, 'Semua');
    expect(names(tester), ['Barang 4', 'Barang 3', 'Barang 2', 'Barang 1']);
  });

  testWidgets('25 barang, filter Belum: digulir sampai bawah → semua dimuat', (
    tester,
  ) async {
    setUpShopping(initialCount: 25, doneNumbers: {25});
    await pumpApp(tester);
    await tapFilter(tester, 'Belum');

    await tester.scrollUntilVisible(
      find.text('Barang 1'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Barang 1'), findsOneWidget);
    expect(find.text('Barang 25'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'checkbox ditekan → status berubah dan tetap benar setelah dimuat ulang',
    (tester) async {
      setUpShopping(initialCount: 2);
      final router = await pumpApp(tester);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Barang 1'),
          matching: find.byType(Checkbox),
        ),
      );
      await tester.pumpAndSettle();

      expect(checkboxOf(tester, 'Barang 1').value, isTrue);
      expect(shopping.byName('Barang 1').isDone, isTrue);

      await reload(tester, router);
      expect(checkboxOf(tester, 'Barang 1').value, isTrue);
      expect(checkboxOf(tester, 'Barang 2').value, isFalse);

      // Dibalik lagi: belum dibeli.
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Barang 1'),
          matching: find.byType(Checkbox),
        ),
      );
      await tester.pumpAndSettle();
      await reload(tester, router);
      expect(checkboxOf(tester, 'Barang 1').value, isFalse);
    },
  );

  testWidgets('filter Belum: barang yang dicentang hilang dari daftar', (
    tester,
  ) async {
    setUpShopping(initialCount: 2);
    await pumpApp(tester);
    await tapFilter(tester, 'Belum');

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Barang 2'),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    expect(names(tester), ['Barang 1']);
  });

  testWidgets('tambah barang → tersimpan di atas daftar', (tester) async {
    setUpShopping(initialCount: 1);
    final router = await pumpApp(tester);

    await tester.tap(find.byTooltip('Tambah barang'));
    await tester.pumpAndSettle();
    expect(find.byType(ShoppingItemFormPage), findsOneWidget);
    expect(pathOf(router), AppRoutes.shoppingNew);

    await tester.enterText(
      find.byKey(const Key('shopping-item-name')),
      '  Susu ',
    );
    await tester.enterText(
      find.byKey(const Key('shopping-item-quantity')),
      '3',
    );
    await save(tester);

    expect(pathOf(router), AppRoutes.shopping);
    expect(names(tester), ['Susu', 'Barang 1']);
    expect(find.text('× 3'), findsOneWidget);
  });

  testWidgets(
    'nama yang sudah ada → "Barang ini sudah ada di daftar." di field nama',
    (tester) async {
      setUpShopping(initialCount: 2);
      final router = await pumpApp(tester);

      await tester.tap(find.byTooltip('Tambah barang'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('shopping-item-name')),
        'barang 1',
      );
      await save(tester);

      final name = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('shopping-item-name')),
          matching: find.byType(TextField),
        ),
      );
      expect(name.decoration!.errorText, 'Barang ini sudah ada di daftar.');
      expect(pathOf(router), AppRoutes.shoppingNew);
      expect(shopping.items, hasLength(2));

      // Mengubah nama menjadi nama barang lain juga ditolak.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barang 2'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('shopping-item-name')),
        'BARANG 1',
      );
      await save(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('shopping-item-name')),
          matching: find.text('Barang ini sudah ada di daftar.'),
        ),
        findsOneWidget,
      );
      expect(shopping.byName('Barang 2').name, 'Barang 2');
    },
  );

  testWidgets('ubah barang → daftar diperbarui', (tester) async {
    setUpShopping(initialCount: 2);
    final router = await pumpApp(tester);

    await tester.tap(find.text('Barang 1'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.shoppingItem('item-1'));

    await tester.enterText(
      find.byKey(const Key('shopping-item-name')),
      'Diubah',
    );
    await save(tester);

    expect(pathOf(router), AppRoutes.shopping);
    expect(names(tester), ['Barang 2', 'Diubah']);
  });

  testWidgets('kembali dari form tanpa hasil → halaman pertama dimuat ulang', (
    tester,
  ) async {
    setUpShopping(initialCount: 1);
    await pumpApp(tester);

    await tester.tap(find.text('Barang 1'));
    await tester.pumpAndSettle();
    // Data berubah di luar daftar ini (misalnya dari perangkat lain).
    await shopping.create(name: 'Dari tempat lain');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(names(tester), ['Dari tempat lain', 'Barang 1']);
  });

  testWidgets('hapus barang dari form → hilang dari daftar', (tester) async {
    setUpShopping(initialCount: 2);
    await pumpApp(tester);

    await tester.tap(find.text('Barang 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();

    expect(names(tester), ['Barang 1']);
    expect(shopping.items.map((i) => i.id), ['item-1']);
  });

  testWidgets(
    '"Hapus yang sudah dibeli" dikonfirmasi → barang itu hilang dari daftar',
    (tester) async {
      setUpShopping(initialCount: 5, doneNumbers: {1, 3, 4});
      final router = await pumpApp(tester);

      await tester.tap(find.byTooltip('Hapus yang sudah dibeli'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(names(tester), ['Barang 5', 'Barang 2']);
      expect(shopping.items.map((i) => i.name), ['Barang 5', 'Barang 2']);

      await reload(tester, router);
      expect(names(tester), ['Barang 5', 'Barang 2']);
      await tapFilter(tester, 'Sudah');
      expect(find.text('Belum ada barang yang sudah dibeli.'), findsOneWidget);
    },
  );

  testWidgets('API mati saat mencentang → SnackBar, status tidak berubah', (
    tester,
  ) async {
    setUpShopping(initialCount: 1);
    await pumpApp(tester);
    shopping.offline = true;

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Tidak dapat terhubung ke server. Periksa koneksi Anda.'),
      findsOneWidget,
    );
    expect(checkboxOf(tester, 'Barang 1').value, isFalse);
  });

  group('dibuka lewat URL', () {
    testWidgets('/shopping/<id> tanpa data dari daftar → kembali ke daftar', (
      tester,
    ) async {
      setUpShopping(initialCount: 1);
      final router = await pumpApp(
        tester,
        initialLocation: AppRoutes.shoppingItem('item-1'),
      );

      expect(find.byType(ShoppingItemFormPage), findsNothing);
      expect(find.byType(ShoppingPage), findsOneWidget);
      expect(pathOf(router), AppRoutes.shopping);
    });

    testWidgets('/shopping/new, simpan → daftar menampilkan data terbaru', (
      tester,
    ) async {
      setUpShopping(initialCount: 1);
      final router = await pumpApp(
        tester,
        initialLocation: AppRoutes.shoppingNew,
      );

      expect(find.text('Tambah barang'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('shopping-item-name')),
        'Roti',
      );
      await save(tester);

      expect(find.byType(ShoppingItemFormPage), findsNothing);
      expect(pathOf(router), AppRoutes.shopping);
      expect(names(tester), ['Roti', 'Barang 1']);
    });
  });
}
