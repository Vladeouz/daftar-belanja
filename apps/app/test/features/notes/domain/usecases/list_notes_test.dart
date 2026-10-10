import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note_page.dart';
import 'package:app/features/notes/domain/usecases/list_notes.dart';

import '../../mocks.dart';

void main() {
  late MockNoteRepository repository;

  setUp(() => repository = MockNoteRepository());

  void stubList(Result<NotePage> result) => when(
    () => repository.list(
      cursor: any(named: 'cursor'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) async => result);

  test('halaman pertama tanpa cursor dan limit bawaan API', () async {
    final page = NotePage(items: [testNote], nextCursor: 'c1');
    stubList(Ok(page));

    expect(await ListNotes(repository)(), Ok(page));
    verify(() => repository.list()).called(1);
  });

  test('meneruskan cursor dan limit', () async {
    const page = NotePage(items: [], nextCursor: null);
    stubList(const Ok(page));

    await ListNotes(repository)(cursor: 'c1', limit: 10);

    verify(() => repository.list(cursor: 'c1', limit: 10)).called(1);
  });

  test('mengembalikan Err dari repository', () async {
    const failure = Failure(FailureCode.network);
    stubList(const Err(failure));

    expect(await ListNotes(repository)(), const Err<NotePage>(failure));
  });
}
