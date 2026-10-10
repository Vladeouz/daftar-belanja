import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/entities/note_page.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_cubit.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_state.dart';

import '../../mocks.dart';

void main() {
  const offline = Failure(FailureCode.network);
  final page1 = [noteNo(3), noteNo(2)];
  final page2 = [noteNo(1)];

  late MockListNotes listNotes;

  /// Hasil ListNotes yang diselesaikan sendiri oleh test.
  late Completer<Result<NotePage>> pending;

  setUp(() => listNotes = MockListNotes());

  void stubList({
    String? cursor,
    required Future<Result<NotePage>> Function() answer,
  }) => when(() => listNotes(cursor: cursor)).thenAnswer((_) => answer());

  Future<Result<NotePage>> ok(List<Note> items, String? nextCursor) async =>
      Ok(NotePage(items: items, nextCursor: nextCursor));

  NotesListLoaded loaded(
    List<Note> items, {
    String? nextCursor,
    bool loadingMore = false,
    Failure? loadMoreFailure,
  }) => NotesListLoaded(
    items: items,
    nextCursor: nextCursor,
    loadingMore: loadingMore,
    loadMoreFailure: loadMoreFailure,
  );

  test('state awal NotesListLoading', () {
    expect(NotesListCubit(listNotes).state, const NotesListLoading());
  });

  group('load (halaman pertama)', () {
    blocTest<NotesListCubit, NotesListState>(
      'berhasil → Loading lalu Loaded dengan nextCursor',
      setUp: () => stubList(answer: () => ok(page1, 'c1')),
      build: () => NotesListCubit(listNotes),
      act: (cubit) => cubit.load(),
      expect: () => [const NotesListLoading(), loaded(page1, nextCursor: 'c1')],
      verify: (_) => verify(() => listNotes()).called(1),
    );

    blocTest<NotesListCubit, NotesListState>(
      'daftar kosong → Loaded tanpa item',
      setUp: () => stubList(answer: () => ok(const [], null)),
      build: () => NotesListCubit(listNotes),
      act: (cubit) => cubit.load(),
      expect: () => [const NotesListLoading(), loaded(const [])],
    );

    blocTest<NotesListCubit, NotesListState>(
      'error jaringan → LoadFailed(network)',
      setUp: () => stubList(answer: () async => const Err(offline)),
      build: () => NotesListCubit(listNotes),
      act: (cubit) => cubit.load(),
      expect: () => const [NotesListLoading(), NotesListLoadFailed(offline)],
    );

    blocTest<NotesListCubit, NotesListState>(
      'coba lagi setelah error jaringan → Loaded',
      setUp: () => stubList(answer: () => ok(page1, null)),
      build: () => NotesListCubit(listNotes),
      seed: () => const NotesListLoadFailed(offline),
      act: (cubit) => cubit.load(),
      expect: () => [const NotesListLoading(), loaded(page1)],
    );

    blocTest<NotesListCubit, NotesListState>(
      'load kedua saat halaman pertama masih dimuat diabaikan',
      setUp: () {
        final pending = Completer<Result<NotePage>>();
        stubList(answer: () => pending.future);
        addTearDown(() => pending.complete(const Err(offline)));
      },
      build: () => NotesListCubit(listNotes),
      act: (cubit) {
        unawaited(cubit.load());
        unawaited(cubit.load());
      },
      expect: () => const [NotesListLoading()],
      verify: (_) => verify(() => listNotes()).called(1),
    );
  });

  group('loadMore (pagination)', () {
    blocTest<NotesListCubit, NotesListState>(
      'memakai nextCursor dan menggabungkan halaman; halaman terakhir → hasMore false',
      setUp: () => stubList(cursor: 'c1', answer: () => ok(page2, null)),
      build: () => NotesListCubit(listNotes),
      seed: () => loaded(page1, nextCursor: 'c1'),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        loaded(page1, nextCursor: 'c1', loadingMore: true),
        loaded([...page1, ...page2]),
      ],
      verify: (cubit) {
        verify(() => listNotes(cursor: 'c1')).called(1);
        expect((cubit.state as NotesListLoaded).hasMore, isFalse);
      },
    );

    blocTest<NotesListCubit, NotesListState>(
      'tiga halaman berurutan tanpa duplikat',
      setUp: () {
        stubList(cursor: 'c1', answer: () => ok([noteNo(2)], 'c2'));
        stubList(cursor: 'c2', answer: () => ok([noteNo(1)], null));
      },
      build: () => NotesListCubit(listNotes),
      seed: () => loaded([noteNo(3)], nextCursor: 'c1'),
      act: (cubit) async {
        await cubit.loadMore();
        await cubit.loadMore();
        await cubit.loadMore(); // sudah halaman terakhir: diabaikan
      },
      skip: 3,
      expect: () => [
        loaded([noteNo(3), noteNo(2), noteNo(1)]),
      ],
      verify: (_) =>
          verify(() => listNotes(cursor: any(named: 'cursor'))).called(2),
    );

    blocTest<NotesListCubit, NotesListState>(
      'error jaringan → daftar tetap, loadMoreFailure terisi; coba lagi berhasil',
      setUp: () {
        var calls = 0;
        stubList(
          cursor: 'c1',
          answer: () =>
              calls++ == 0 ? Future.value(const Err(offline)) : ok(page2, null),
        );
      },
      build: () => NotesListCubit(listNotes),
      seed: () => loaded(page1, nextCursor: 'c1'),
      act: (cubit) async {
        await cubit.loadMore();
        await cubit.loadMore();
      },
      expect: () => [
        loaded(page1, nextCursor: 'c1', loadingMore: true),
        loaded(page1, nextCursor: 'c1', loadMoreFailure: offline),
        loaded(page1, nextCursor: 'c1', loadingMore: true),
        loaded([...page1, ...page2]),
      ],
    );

    blocTest<NotesListCubit, NotesListState>(
      'diabaikan bila semua sudah dimuat',
      build: () => NotesListCubit(listNotes),
      seed: () => loaded(page1),
      act: (cubit) => cubit.loadMore(),
      expect: () => const <NotesListState>[],
      verify: (_) => verifyNever(() => listNotes(cursor: any(named: 'cursor'))),
    );

    blocTest<NotesListCubit, NotesListState>(
      'diabaikan sebelum halaman pertama tampil',
      build: () => NotesListCubit(listNotes),
      act: (cubit) => cubit.loadMore(),
      expect: () => const <NotesListState>[],
      verify: (_) => verifyNever(() => listNotes(cursor: any(named: 'cursor'))),
    );

    blocTest<NotesListCubit, NotesListState>(
      'loadMore kedua saat masih memuat diabaikan',
      setUp: () {
        final pending = Completer<Result<NotePage>>();
        stubList(cursor: 'c1', answer: () => pending.future);
        addTearDown(() => pending.complete(const Err(offline)));
      },
      build: () => NotesListCubit(listNotes),
      seed: () => loaded(page1, nextCursor: 'c1'),
      act: (cubit) {
        unawaited(cubit.loadMore());
        unawaited(cubit.loadMore());
      },
      expect: () => [loaded(page1, nextCursor: 'c1', loadingMore: true)],
      verify: (_) => verify(() => listNotes(cursor: 'c1')).called(1),
    );

    blocTest<NotesListCubit, NotesListState>(
      'note dihapus selama memuat → hasil digabung ke daftar terbaru',
      setUp: () {
        pending = Completer<Result<NotePage>>();
        stubList(cursor: 'c1', answer: () => pending.future);
      },
      build: () => NotesListCubit(listNotes),
      seed: () => loaded(page1, nextCursor: 'c1'),
      act: (cubit) async {
        final more = cubit.loadMore();
        cubit.noteDeleted(noteNo(3).id);
        pending.complete(Ok(NotePage(items: page2, nextCursor: null)));
        await more;
      },
      expect: () => [
        loaded(page1, nextCursor: 'c1', loadingMore: true),
        loaded([noteNo(2)], nextCursor: 'c1', loadingMore: true),
        loaded([noteNo(2), noteNo(1)]),
      ],
    );
  });

  group('perubahan dari form', () {
    final edited = Note(
      id: noteNo(2).id,
      title: 'Diubah',
      body: 'Isi baru',
      createdAt: noteNo(2).createdAt,
      updatedAt: DateTime.utc(2026, 10, 2),
    );

    blocTest<NotesListCubit, NotesListState>(
      'note baru → paling atas, cursor tidak berubah',
      build: () => NotesListCubit(listNotes),
      seed: () => loaded(page1, nextCursor: 'c1'),
      act: (cubit) => cubit.noteSaved(noteNo(9)),
      expect: () => [
        loaded([noteNo(9), ...page1], nextCursor: 'c1'),
      ],
    );

    blocTest<NotesListCubit, NotesListState>(
      'note diubah → diganti di tempatnya',
      build: () => NotesListCubit(listNotes),
      seed: () => loaded(page1, nextCursor: 'c1'),
      act: (cubit) => cubit.noteSaved(edited),
      expect: () => [
        loaded([noteNo(3), edited], nextCursor: 'c1'),
      ],
    );

    blocTest<NotesListCubit, NotesListState>(
      'note dihapus → hilang dari daftar',
      build: () => NotesListCubit(listNotes),
      seed: () => loaded(page1, nextCursor: 'c1'),
      act: (cubit) => cubit.noteDeleted(noteNo(3).id),
      expect: () => [
        loaded([noteNo(2)], nextCursor: 'c1'),
      ],
    );

    blocTest<NotesListCubit, NotesListState>(
      'diabaikan bila daftar belum tampil',
      build: () => NotesListCubit(listNotes),
      seed: () => const NotesListLoadFailed(offline),
      act: (cubit) => cubit
        ..noteSaved(noteNo(9))
        ..noteDeleted(noteNo(3).id),
      expect: () => const <NotesListState>[],
    );
  });

  test('ditutup sebelum hasil tiba → tidak emit setelah close', () async {
    final pending = Completer<Result<NotePage>>();
    stubList(answer: () => pending.future);
    final cubit = NotesListCubit(listNotes);

    final load = cubit.load();
    await cubit.close();
    pending.complete(Ok(NotePage(items: page1, nextCursor: null)));

    await expectLater(load, completes);
    expect(cubit.state, const NotesListLoading());
  });
}
