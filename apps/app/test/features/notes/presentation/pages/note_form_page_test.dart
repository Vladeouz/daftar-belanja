import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/notes/presentation/cubit/note_form_cubit.dart';
import 'package:app/features/notes/presentation/cubit/note_form_state.dart';
import 'package:app/features/notes/presentation/pages/note_form_page.dart';

import '../../mocks.dart';

void main() {
  late MockNoteFormCubit cubit;

  setUp(() {
    cubit = MockNoteFormCubit();
    when(
      () => cubit.save(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {});
    when(() => cubit.delete()).thenAnswer((_) async {});
    when(() => cubit.load(any())).thenAnswer((_) async {});
  });

  /// Halaman form di atas halaman "daftar" sederhana, agar `context.pop(state)` bisa diuji.
  /// [results] menampung nilai yang dikembalikan halaman form.
  Future<List<Object?>> pumpPage(
    WidgetTester tester,
    NoteFormState state, {
    String? noteId,
    Stream<NoteFormState> stream = const Stream.empty(),
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
              builder: (_, _) => BlocProvider<NoteFormCubit>.value(
                value: cubit,
                child: NoteFormPage(noteId: noteId),
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

  InputDecoration decorationOf(WidgetTester tester, String key) => tester
      .widget<TextField>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(TextField),
        ),
      )
      .decoration!;

  Finder saveButton() => find.widgetWithText(FilledButton, 'Simpan');

  group('error validasi', () {
    testWidgets('judul kosong → "Wajib diisi." di field judul, tidak dikirim', (
      tester,
    ) async {
      await pumpPage(tester, const NoteFormEditing());

      await tester.enterText(find.byKey(const Key('note-title')), '   ');
      await tester.tap(saveButton());
      await tester.pump();

      expect(decorationOf(tester, 'note-title').errorText, 'Wajib diisi.');
      verifyNever(
        () => cubit.save(
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      );
    });

    testWidgets('error validasi API pada title → tampil di field judul', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const NoteFormEditing(
          failure: Failure(
            FailureCode.validation,
            message: 'Request validation failed',
            fieldErrors: {
              'title': [FieldIssue('too_big', 'Too big')],
            },
          ),
        ),
      );

      expect(decorationOf(tester, 'note-title').errorText, 'Terlalu panjang.');
      expect(decorationOf(tester, 'note-body').errorText, isNull);
      // Pesan umum dan pesan Inggris dari server tidak ditampilkan.
      expect(find.text('Periksa kembali isian Anda.'), findsNothing);
      expect(find.textContaining('Request validation'), findsNothing);
    });

    testWidgets('error validasi API pada body → tampil di field isi', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const NoteFormEditing(
          failure: Failure(
            FailureCode.validation,
            fieldErrors: {
              'body': [FieldIssue('too_big', 'Too big')],
            },
          ),
        ),
      );

      expect(decorationOf(tester, 'note-body').errorText, 'Terlalu panjang.');
      expect(decorationOf(tester, 'note-title').errorText, isNull);
    });

    testWidgets('error validasi tanpa field (_root) → pesan umum validasi', (
      tester,
    ) async {
      await pumpPage(
        tester,
        NoteFormEditing(
          note: testNote,
          failure: const Failure(
            FailureCode.validation,
            fieldErrors: {
              '_root': [FieldIssue('custom', 'At least one field')],
            },
          ),
        ),
        noteId: testNote.id,
      );

      expect(find.text('Periksa kembali isian Anda.'), findsOneWidget);
    });
  });

  testWidgets('error jaringan saat menyimpan → pesan di atas tombol simpan', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const NoteFormEditing(failure: Failure(FailureCode.network)),
    );

    expect(
      find.text('Tidak dapat terhubung ke server. Periksa koneksi Anda.'),
      findsOneWidget,
    );
  });

  testWidgets('note baru: judul halaman, tanpa tombol hapus, kirim isian', (
    tester,
  ) async {
    await pumpPage(tester, const NoteFormEditing());

    expect(find.text('Catatan baru'), findsOneWidget);
    expect(find.byTooltip('Hapus'), findsNothing);

    await tester.enterText(find.byKey(const Key('note-title')), 'Belanja');
    await tester.enterText(find.byKey(const Key('note-body')), 'Susu');
    await tester.tap(saveButton());

    verify(() => cubit.save(title: 'Belanja', body: 'Susu')).called(1);
  });

  testWidgets('ubah note: field terisi dari note', (tester) async {
    await pumpPage(
      tester,
      NoteFormEditing(note: testNote),
      noteId: testNote.id,
    );

    expect(find.text('Ubah catatan'), findsOneWidget);
    expect(find.text(testNote.title), findsOneWidget);
    expect(find.text(testNote.body), findsOneWidget);

    await tester.tap(saveButton());
    verify(() => cubit.save(title: testNote.title, body: testNote.body))
        .called(1);
  });

  testWidgets('saat menyimpan: tombol dan field nonaktif, indikator tampil', (
    tester,
  ) async {
    await pumpPage(
      tester,
      NoteFormEditing(note: testNote, status: NoteFormStatus.saving),
      noteId: testNote.id,
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
    final title = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('note-title')),
        matching: find.byType(TextField),
      ),
    );
    expect(title.enabled, isFalse);
  });

  group('hapus', () {
    testWidgets('konfirmasi "Hapus" → cubit.delete()', (tester) async {
      await pumpPage(
        tester,
        NoteFormEditing(note: testNote),
        noteId: testNote.id,
      );

      await tester.tap(find.byTooltip('Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus catatan?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      verify(() => cubit.delete()).called(1);
    });

    testWidgets('"Batal" → tidak menghapus', (tester) async {
      await pumpPage(
        tester,
        NoteFormEditing(note: testNote),
        noteId: testNote.id,
      );

      await tester.tap(find.byTooltip('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus catatan?'), findsNothing);
      verifyNever(() => cubit.delete());
    });
  });

  group('selesai → halaman ditutup membawa hasil', () {
    testWidgets('Saved', (tester) async {
      final results = await pumpPage(
        tester,
        const NoteFormEditing(),
        stream: Stream.value(NoteFormSaved(testNote)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NoteFormPage), findsNothing);
      expect(results, [NoteFormSaved(testNote)]);
    });

    testWidgets('Deleted', (tester) async {
      final results = await pumpPage(
        tester,
        NoteFormEditing(note: testNote),
        noteId: testNote.id,
        stream: Stream.value(NoteFormDeleted(testNote.id)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NoteFormPage), findsNothing);
      expect(results, [NoteFormDeleted(testNote.id)]);
    });
  });

  group('dibuka lewat URL', () {
    testWidgets('sedang memuat → indikator, tanpa form', (tester) async {
      whenListen(
        cubit,
        const Stream<NoteFormState>.empty(),
        initialState: const NoteFormLoading(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NoteFormCubit>.value(
            value: cubit,
            child: NoteFormPage(noteId: testNote.id),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('note-title')), findsNothing);
    });

    testWidgets('gagal dimuat → pesan dan "Coba lagi" memuat ulang', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const NoteFormLoadFailed(Failure(FailureCode.notFound)),
        noteId: testNote.id,
      );

      expect(find.text('Data tidak ditemukan.'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));

      verify(() => cubit.load(testNote.id)).called(1);
    });
  });
}
