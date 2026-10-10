import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/usecases/delete_shopping_item.dart';

import '../../mocks.dart';

void main() {
  late MockShoppingItemRepository repository;

  setUp(() => repository = MockShoppingItemRepository());

  test('menghapus lewat repository', () async {
    when(() => repository.delete(any()))
        .thenAnswer((_) async => const Ok(null));

    expect(
      await DeleteShoppingItem(repository)(testShoppingItem.id),
      const Ok<void>(null),
    );
    verify(() => repository.delete(testShoppingItem.id)).called(1);
  });

  test('mengembalikan Err dari repository', () async {
    const failure = Failure(FailureCode.notFound);
    when(() => repository.delete(any()))
        .thenAnswer((_) async => const Err(failure));

    expect(
      await DeleteShoppingItem(repository)('lain'),
      const Err<void>(failure),
    );
  });
}
