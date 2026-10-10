import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/usecases/delete_note.dart';

import '../../mocks.dart';

void main() {
  late MockNoteRepository repository;

  setUp(() => repository = MockNoteRepository());

  test('menghapus lewat repository', () async {
    when(() => repository.delete(any()))
        .thenAnswer((_) async => const Ok(null));

    expect(await DeleteNote(repository)(testNote.id), const Ok<void>(null));
    verify(() => repository.delete(testNote.id)).called(1);
  });

  test('mengembalikan Err dari repository', () async {
    const failure = Failure(FailureCode.notFound);
    when(() => repository.delete(any()))
        .thenAnswer((_) async => const Err(failure));

    expect(await DeleteNote(repository)('lain'), const Err<void>(failure));
  });
}
