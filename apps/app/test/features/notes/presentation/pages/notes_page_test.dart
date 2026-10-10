import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_cubit.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_state.dart';
import 'package:app/features/notes/presentation/pages/notes_page.dart';

import '../../mocks.dart';

void main() {
  const offline = Failure(FailureCode.network);
  const offlineMessage =
      'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
  final twentyNotes = [for (var i = 20; i >= 1; i--) noteNo(i)];

  late MockNotesListCubit cubit;

  setUp(() {
    cubit = MockNotesListCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.loadMore()).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester, NotesListState state) async {
    whenListen(
      cubit,
      const Stream<NotesListState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotesListCubit>.value(
          value: cubit,
          child: const NotesPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('memuat halaman pertama → indikator', (tester) async {
    await pumpPage(tester, const NotesListLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('API mati → pesan jaringan dan "Coba lagi" memuat ulang', (
    tester,
  ) async {
    await pumpPage(tester, const NotesListLoadFailed(offline));

    expect(find.text(offlineMessage), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Coba lagi'));

    verify(() => cubit.load()).called(1);
  });

  testWidgets('daftar kosong → "Belum ada catatan."', (tester) async {
    await pumpPage(tester, const NotesListLoaded(items: [], nextCursor: null));

    expect(find.text('Belum ada catatan.'), findsOneWidget);
  });

  testWidgets('menampilkan judul dan cuplikan isi', (tester) async {
    await pumpPage(
      tester,
      NotesListLoaded(items: [testNote], nextCursor: null),
    );

    expect(find.text(testNote.title), findsOneWidget);
    expect(find.text(testNote.body), findsOneWidget);
    expect(find.byTooltip('Catatan baru'), findsOneWidget);
  });

  testWidgets('digulir sampai bawah → halaman berikutnya dimuat (loadMore)', (
    tester,
  ) async {
    await pumpPage(
      tester,
      NotesListLoaded(items: twentyNotes, nextCursor: 'c1'),
    );
    verifyNever(() => cubit.loadMore());

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    await tester.pump();

    verify(() => cubit.loadMore()).called(1);
  });

  testWidgets(
    'halaman pertama tidak memenuhi layar → halaman berikutnya langsung dimuat',
    (tester) async {
      await pumpPage(
        tester,
        NotesListLoaded(items: [noteNo(2), noteNo(1)], nextCursor: 'c1'),
      );
      await tester.pump();

      verify(() => cubit.loadMore()).called(1);
    },
  );

  testWidgets('halaman terakhir → tidak memuat lagi', (tester) async {
    await pumpPage(
      tester,
      NotesListLoaded(items: twentyNotes, nextCursor: null),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    await tester.pump();

    verifyNever(() => cubit.loadMore());
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('halaman berikutnya gagal → pesan dan "Coba lagi", tanpa '
      'mencoba ulang otomatis', (tester) async {
    await pumpPage(
      tester,
      NotesListLoaded(
        items: [noteNo(1)],
        nextCursor: 'c1',
        loadMoreFailure: offline,
      ),
    );
    await tester.pump();

    expect(find.text(noteNo(1).title), findsOneWidget);
    expect(find.text(offlineMessage), findsOneWidget);
    verifyNever(() => cubit.loadMore());

    await tester.tap(find.widgetWithText(TextButton, 'Coba lagi'));
    verify(() => cubit.loadMore()).called(1);
  });

  testWidgets('sedang memuat halaman berikutnya → indikator di bawah daftar', (
    tester,
  ) async {
    await pumpPage(
      tester,
      NotesListLoaded(items: [noteNo(1)], nextCursor: 'c1', loadingMore: true),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    verifyNever(() => cubit.loadMore());
  });
}
