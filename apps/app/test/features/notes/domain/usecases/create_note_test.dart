import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/usecases/create_note.dart';

import '../../mocks.dart';

void main() {
  late MockNoteRepository repository;

  setUp(() => repository = MockNoteRepository());

  void stubCreate(Result<Note> result) => when(
    () => repository.create(
      title: any(named: 'title'),
      body: any(named: 'body'),
    ),
  ).thenAnswer((_) async => result);

  test('judul dirapikan, isi dikirim apa adanya', () async {
    stubCreate(Ok(testNote));

    final result = await CreateNote(repository)(
      title: '  Belanja ',
      body: ' Susu dan roti ',
    );

    expect(result, Ok(testNote));
    verify(() => repository.create(title: 'Belanja', body: ' Susu dan roti '))
        .called(1);
  });

  test('tanpa isi → body null (tidak dikirim)', () async {
    stubCreate(Ok(testNote));

    await CreateNote(repository)(title: 'Belanja');

    verify(() => repository.create(title: 'Belanja')).called(1);
  });

  test(
    'judul kosong tetap dikirim; Err validasi dari API diteruskan',
    () async {
      const failure = Failure(
        FailureCode.validation,
        fieldErrors: {
          'title': [FieldIssue('too_small', 'Too small')],
        },
      );
      stubCreate(const Err(failure));

      final result = await CreateNote(repository)(title: '   ');

      expect(result, const Err<Note>(failure));
      verify(() => repository.create(title: '')).called(1);
    },
  );
}
