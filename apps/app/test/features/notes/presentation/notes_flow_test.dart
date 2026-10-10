import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:app/app.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/features/auth/auth_dependencies.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';
import 'package:app/features/notes/notes_dependencies.dart';
import 'package:app/features/notes/presentation/pages/note_form_page.dart';
import 'package:app/features/notes/presentation/pages/notes_page.dart';

import '../../auth/fake_auth_repository.dart';
import '../fake_note_repository.dart';

/// Alur fitur notes lewat router, Cubit, dan use case asli; hanya repository yang palsu
/// ([FakeNoteRepository] meniru API).
void main() {
  late GetIt container;
  late FakeNoteRepository notes;

  void setUpNotes({int initialCount = 0}) {
    notes = FakeNoteRepository(initialCount: initialCount);
    container = GetIt.asNewInstance();
    registerAuthDependencies(container);
    registerNotesDependencies(container);
    container
      ..unregister<AuthRepository>()
      ..registerSingleton<AuthRepository>(
        FakeAuthRepository(
          signedIn: FakeAuthRepository.userFor('a@example.com'),
        ),
      )
      ..unregister<NoteRepository>()
      ..registerSingleton<NoteRepository>(notes);
    addTearDown(container.reset);
  }

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String initialLocation = AppRoutes.notes,
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

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();
  }

  testWidgets('25 note: digulir sampai bawah → halaman kedua dimuat', (
    tester,
  ) async {
    setUpNotes(initialCount: 25);
    await pumpApp(tester);

    expect(find.text('Catatan 25'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Catatan 1'),
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catatan 1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'buat note: judul kosong ditolak, lalu tersimpan di atas daftar',
    (tester) async {
      setUpNotes(initialCount: 2);
      final router = await pumpApp(tester);

      await tester.tap(find.byTooltip('Catatan baru'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteFormPage), findsOneWidget);
      expect(pathOf(router), AppRoutes.noteNew);

      await save(tester);
      expect(find.text('Wajib diisi.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('note-title')), '  Belanja ');
      await tester.enterText(find.byKey(const Key('note-body')), 'Susu');
      await save(tester);

      expect(pathOf(router), AppRoutes.notes);
      expect(notes.notes.first.title, 'Belanja');
      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .toList();
      expect(titles, ['Belanja', 'Catatan 2', 'Catatan 1']);
    },
  );

  testWidgets('ubah note → daftar diperbarui', (tester) async {
    setUpNotes(initialCount: 2);
    final router = await pumpApp(tester);

    await tester.tap(find.text('Catatan 1'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteFormPage), findsOneWidget);
    expect(pathOf(router), AppRoutes.note('note-1'));
    expect(find.text('Isi 1'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('note-title')), 'Diubah');
    await save(tester);

    expect(pathOf(router), AppRoutes.notes);
    expect(find.text('Diubah'), findsOneWidget);
    expect(find.text('Catatan 1'), findsNothing);
  });

  testWidgets('hapus note → hilang dari daftar', (tester) async {
    setUpNotes(initialCount: 2);
    final router = await pumpApp(tester);

    await tester.tap(find.text('Catatan 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();

    expect(pathOf(router), AppRoutes.notes);
    expect(find.text('Catatan 2'), findsNothing);
    expect(find.text('Catatan 1'), findsOneWidget);
    expect(notes.notes.map((n) => n.id), ['note-1']);
  });

  testWidgets('API mati → pesan jaringan; coba lagi setelah hidup → daftar', (
    tester,
  ) async {
    setUpNotes(initialCount: 1);
    notes.offline = true;
    await pumpApp(tester);

    expect(
      find.text('Tidak dapat terhubung ke server. Periksa koneksi Anda.'),
      findsOneWidget,
    );

    notes.offline = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan 1'), findsOneWidget);
  });

  testWidgets('kembali dari form tanpa menyimpan → daftar tidak berubah', (
    tester,
  ) async {
    setUpNotes(initialCount: 1);
    final router = await pumpApp(tester);

    await tester.tap(find.text('Catatan 1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-title')), 'Tidak jadi');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(pathOf(router), AppRoutes.notes);
    expect(find.text('Catatan 1'), findsOneWidget);
    expect(notes.notes.single.title, 'Catatan 1');
  });

  testWidgets('kembali dari form tanpa hasil → halaman pertama dimuat ulang', (
    tester,
  ) async {
    setUpNotes(initialCount: 1);
    await pumpApp(tester);

    await tester.tap(find.text('Catatan 1'));
    await tester.pumpAndSettle();
    // Data berubah di luar daftar ini (misalnya dari perangkat lain).
    await notes.create(title: 'Dari tempat lain');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Dari tempat lain'), findsOneWidget);
    expect(find.text('Catatan 1'), findsOneWidget);
  });

  group('dibuka lewat URL', () {
    testWidgets('/notes/<id> → note dimuat dari API', (tester) async {
      setUpNotes(initialCount: 2);
      await pumpApp(tester, initialLocation: AppRoutes.note('note-2'));

      expect(find.byType(NoteFormPage), findsOneWidget);
      expect(find.text('Catatan 2'), findsOneWidget);
      expect(find.text('Isi 2'), findsOneWidget);
    });

    testWidgets(
      '/notes/<id>, simpan, kembali → daftar menampilkan data terbaru',
      (tester) async {
        setUpNotes(initialCount: 2);
        final router = await pumpApp(
          tester,
          initialLocation: AppRoutes.note('note-1'),
        );

        await tester.enterText(find.byKey(const Key('note-title')), 'Diubah');
        await save(tester);

        expect(find.byType(NoteFormPage), findsNothing);
        expect(pathOf(router), AppRoutes.notes);
        final titles = tester
            .widgetList<ListTile>(find.byType(ListTile))
            .map((tile) => (tile.title! as Text).data)
            .toList();
        expect(titles, ['Catatan 2', 'Diubah']);
      },
    );

    testWidgets('/notes/<id> yang tidak ada → "Data tidak ditemukan."', (
      tester,
    ) async {
      setUpNotes();
      await pumpApp(tester, initialLocation: AppRoutes.note('tidak-ada'));

      expect(find.text('Data tidak ditemukan.'), findsOneWidget);
      expect(find.byKey(const Key('note-title')), findsNothing);
    });

    testWidgets('/notes/new → form kosong, daftar di bawahnya', (tester) async {
      setUpNotes(initialCount: 1);
      final router = await pumpApp(tester, initialLocation: AppRoutes.noteNew);

      expect(find.text('Catatan baru'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(NotesPage), findsOneWidget);
      expect(pathOf(router), AppRoutes.notes);
    });
  });
}
