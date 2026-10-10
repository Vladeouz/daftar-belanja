import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/usecases/get_note.dart';

import '../../mocks.dart';

void main() {
  late MockNoteRepository repository;

  setUp(() => repository = MockNoteRepository());

  test('mengembalikan note dari repository', () async {
    when(() => repository.get(testNote.id))
        .thenAnswer((_) async => Ok(testNote));

    expect(await GetNote(repository)(testNote.id), Ok(testNote));
  });

  test('note tidak ada atau milik user lain → Err(notFound)', () async {
    const failure = Failure(FailureCode.notFound);
    when(() => repository.get(any()))
        .thenAnswer((_) async => const Err(failure));

    expect(await GetNote(repository)('lain'), const Err<Note>(failure));
  });
}
