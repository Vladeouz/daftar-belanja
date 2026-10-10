import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/usecases/update_note.dart';

import '../../mocks.dart';

void main() {
  late MockNoteRepository repository;

  setUp(() => repository = MockNoteRepository());

  void stubUpdate(Result<Note> result) => when(
    () => repository.update(
      any(),
      title: any(named: 'title'),
      body: any(named: 'body'),
    ),
  ).thenAnswer((_) async => result);

  test('judul dirapikan, isi dikirim apa adanya', () async {
    stubUpdate(Ok(testNote));

    final result = await UpdateNote(repository)(
      testNote.id,
      title: ' Belanja  ',
      body: 'Susu ',
    );

    expect(result, Ok(testNote));
    verify(
      () => repository.update(testNote.id, title: 'Belanja', body: 'Susu '),
    ).called(1);
  });

  test('hanya isi → judul null (tidak diubah)', () async {
    stubUpdate(Ok(testNote));

    await UpdateNote(repository)(testNote.id, body: '');

    verify(() => repository.update(testNote.id, body: '')).called(1);
  });

  test('mengembalikan Err dari repository', () async {
    const failure = Failure(FailureCode.notFound);
    stubUpdate(const Err(failure));

    expect(
      await UpdateNote(repository)('lain', title: 'Judul'),
      const Err<Note>(failure),
    );
  });
}
