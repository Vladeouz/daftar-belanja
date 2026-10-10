import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/presentation/cubit/note_form_cubit.dart';
import 'package:app/features/notes/presentation/cubit/note_form_state.dart';

import '../../mocks.dart';

void main() {
  const offline = Failure(FailureCode.network);
  const notFound = Failure(FailureCode.notFound, message: 'Note not found');
  const titleTooSmall = Failure(
    FailureCode.validation,
    fieldErrors: {
      'title': [FieldIssue('too_small', 'Too small')],
    },
  );
  final edited = Note(
    id: testNote.id,
    title: 'Belanja mingguan',
    body: 'Susu, roti, telur',
    createdAt: testNote.createdAt,
    updatedAt: DateTime.utc(2026, 10, 2),
  );

  late MockGetNote getNote;
  late MockCreateNote createNote;
  late MockUpdateNote updateNote;
  late MockDeleteNote deleteNote;

  setUp(() {
    getNote = MockGetNote();
    createNote = MockCreateNote();
    updateNote = MockUpdateNote();
    deleteNote = MockDeleteNote();
  });

  NoteFormCubit build() => NoteFormCubit(
    getNote: getNote,
    createNote: createNote,
    updateNote: updateNote,
    deleteNote: deleteNote,
  );

  void stubCreate(Future<Result<Note>> Function() answer) => when(
    () => createNote(
      title: any(named: 'title'),
      body: any(named: 'body'),
    ),
  ).thenAnswer((_) => answer());

  void stubUpdate(Future<Result<Note>> Function() answer) => when(
    () => updateNote(
      any(),
      title: any(named: 'title'),
      body: any(named: 'body'),
    ),
  ).thenAnswer((_) => answer());

  test('state awal: form note baru', () {
    final state = build().state;
    expect(state, const NoteFormEditing());
    expect((state as NoteFormEditing).isNew, isTrue);
  });

  group('membuka note', () {
    blocTest<NoteFormCubit, NoteFormState>(
      'edit (note dari daftar) → form berisi note tanpa memanggil API',
      build: build,
      act: (cubit) => cubit.edit(testNote),
      expect: () => [NoteFormEditing(note: testNote)],
      verify: (_) => verifyNever(() => getNote(any())),
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'load (dibuka lewat URL) → Loading lalu form berisi note',
      setUp: () =>
          when(() => getNote(testNote.id))
              .thenAnswer((_) async => Ok(testNote)),
      build: build,
      act: (cubit) => cubit.load(testNote.id),
      expect: () => [const NoteFormLoading(), NoteFormEditing(note: testNote)],
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'load note yang tidak ada → LoadFailed(notFound)',
      setUp: () =>
          when(() => getNote(any()))
              .thenAnswer((_) async => const Err(notFound)),
      build: build,
      act: (cubit) => cubit.load('tidak-ada'),
      expect: () => const [NoteFormLoading(), NoteFormLoadFailed(notFound)],
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'load gagal koneksi → LoadFailed(network)',
      setUp: () =>
          when(() => getNote(any()))
              .thenAnswer((_) async => const Err(offline)),
      build: build,
      act: (cubit) => cubit.load(testNote.id),
      expect: () => const [NoteFormLoading(), NoteFormLoadFailed(offline)],
    );
  });

  group('simpan note baru', () {
    blocTest<NoteFormCubit, NoteFormState>(
      'berhasil → saving lalu Saved berisi note dari API',
      setUp: () => stubCreate(() async => Ok(testNote)),
      build: build,
      act: (cubit) => cubit.save(title: 'Belanja', body: 'Susu dan roti'),
      expect: () => [
        const NoteFormEditing(status: NoteFormStatus.saving),
        NoteFormSaved(testNote),
      ],
      verify: (_) {
        verify(() => createNote(title: 'Belanja', body: 'Susu dan roti'))
            .called(1);
        verifyNever(
          () => updateNote(
            any(),
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        );
      },
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'judul ditolak API → kembali ke form dengan fieldErrors title',
      setUp: () => stubCreate(() async => const Err(titleTooSmall)),
      build: build,
      act: (cubit) => cubit.save(title: '   ', body: ''),
      expect: () => const [
        NoteFormEditing(status: NoteFormStatus.saving),
        NoteFormEditing(failure: titleTooSmall),
      ],
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'error jaringan → kembali ke form dengan failure network',
      setUp: () => stubCreate(() async => const Err(offline)),
      build: build,
      act: (cubit) => cubit.save(title: 'Belanja', body: ''),
      expect: () => const [
        NoteFormEditing(status: NoteFormStatus.saving),
        NoteFormEditing(failure: offline),
      ],
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'percobaan ulang setelah gagal: failure lama dihapus saat menyimpan',
      setUp: () => stubCreate(() async => Ok(testNote)),
      build: build,
      seed: () => const NoteFormEditing(failure: offline),
      act: (cubit) => cubit.save(title: 'Belanja', body: ''),
      expect: () => [
        const NoteFormEditing(status: NoteFormStatus.saving),
        NoteFormSaved(testNote),
      ],
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'simpan kedua saat masih menyimpan diabaikan',
      setUp: () {
        final pending = Completer<Result<Note>>();
        stubCreate(() => pending.future);
        addTearDown(() => pending.complete(Ok(testNote)));
      },
      build: build,
      act: (cubit) {
        unawaited(cubit.save(title: 'Belanja', body: ''));
        unawaited(cubit.save(title: 'Belanja', body: ''));
      },
      expect: () => const [NoteFormEditing(status: NoteFormStatus.saving)],
      verify: (_) => verify(
        () => createNote(
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).called(1),
    );
  });

  group('ubah note', () {
    blocTest<NoteFormCubit, NoteFormState>(
      'berhasil → memanggil UpdateNote dengan id note, lalu Saved',
      setUp: () => stubUpdate(() async => Ok(edited)),
      build: build,
      seed: () => NoteFormEditing(note: testNote),
      act: (cubit) =>
          cubit.save(title: 'Belanja mingguan', body: 'Susu, roti, telur'),
      expect: () => [
        NoteFormEditing(note: testNote, status: NoteFormStatus.saving),
        NoteFormSaved(edited),
      ],
      verify: (_) {
        verify(
          () => updateNote(
            testNote.id,
            title: 'Belanja mingguan',
            body: 'Susu, roti, telur',
          ),
        ).called(1);
        verifyNever(
          () => createNote(
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        );
      },
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'judul ditolak API → form tetap berisi note, dengan fieldErrors title',
      setUp: () => stubUpdate(() async => const Err(titleTooSmall)),
      build: build,
      seed: () => NoteFormEditing(note: testNote),
      act: (cubit) => cubit.save(title: '', body: 'x'),
      expect: () => [
        NoteFormEditing(note: testNote, status: NoteFormStatus.saving),
        NoteFormEditing(note: testNote, failure: titleTooSmall),
      ],
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'note sudah dihapus di tempat lain → failure notFound',
      setUp: () => stubUpdate(() async => const Err(notFound)),
      build: build,
      seed: () => NoteFormEditing(note: testNote),
      act: (cubit) => cubit.save(title: 'Belanja', body: ''),
      expect: () => [
        NoteFormEditing(note: testNote, status: NoteFormStatus.saving),
        NoteFormEditing(note: testNote, failure: notFound),
      ],
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'diabaikan saat note masih dimuat',
      build: build,
      seed: () => const NoteFormLoading(),
      act: (cubit) => cubit.save(title: 'Belanja', body: ''),
      expect: () => const <NoteFormState>[],
    );
  });

  group('hapus note', () {
    blocTest<NoteFormCubit, NoteFormState>(
      'berhasil → deleting lalu Deleted berisi id',
      setUp: () =>
          when(() => deleteNote(testNote.id))
              .thenAnswer((_) async => const Ok(null)),
      build: build,
      seed: () => NoteFormEditing(note: testNote),
      act: (cubit) => cubit.delete(),
      expect: () => [
        NoteFormEditing(note: testNote, status: NoteFormStatus.deleting),
        NoteFormDeleted(testNote.id),
      ],
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'error jaringan → kembali ke form dengan failure network',
      setUp: () =>
          when(() => deleteNote(any()))
              .thenAnswer((_) async => const Err(offline)),
      build: build,
      seed: () => NoteFormEditing(note: testNote),
      act: (cubit) => cubit.delete(),
      expect: () => [
        NoteFormEditing(note: testNote, status: NoteFormStatus.deleting),
        NoteFormEditing(note: testNote, failure: offline),
      ],
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'diabaikan untuk note baru',
      build: build,
      act: (cubit) => cubit.delete(),
      expect: () => const <NoteFormState>[],
      verify: (_) => verifyNever(() => deleteNote(any())),
    );

    blocTest<NoteFormCubit, NoteFormState>(
      'diabaikan saat masih menyimpan',
      build: build,
      seed: () =>
          NoteFormEditing(note: testNote, status: NoteFormStatus.saving),
      act: (cubit) => cubit.delete(),
      expect: () => const <NoteFormState>[],
      verify: (_) => verifyNever(() => deleteNote(any())),
    );
  });

  test('ditutup sebelum hasil tiba → tidak emit setelah close', () async {
    final pending = Completer<Result<Note>>();
    stubCreate(() => pending.future);
    final cubit = build();

    final save = cubit.save(title: 'Belanja', body: '');
    await cubit.close();
    pending.complete(Ok(testNote));

    await expectLater(save, completes);
    expect(cubit.state, const NoteFormEditing(status: NoteFormStatus.saving));
  });
}
