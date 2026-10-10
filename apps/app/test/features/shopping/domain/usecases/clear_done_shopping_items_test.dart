import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/usecases/clear_done_shopping_items.dart';

import '../../mocks.dart';

void main() {
  late MockShoppingItemRepository repository;

  setUp(() => repository = MockShoppingItemRepository());

  test('mengembalikan jumlah barang yang terhapus', () async {
    when(() => repository.clearDone()).thenAnswer((_) async => const Ok(3));

    expect(await ClearDoneShoppingItems(repository)(), const Ok(3));
    verify(() => repository.clearDone()).called(1);
  });

  test('mengembalikan Err dari repository', () async {
    const failure = Failure(FailureCode.network);
    when(() => repository.clearDone())
        .thenAnswer((_) async => const Err(failure));

    expect(await ClearDoneShoppingItems(repository)(), const Err<int>(failure));
  });
}
