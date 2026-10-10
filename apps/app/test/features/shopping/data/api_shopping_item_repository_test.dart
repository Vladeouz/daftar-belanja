import 'package:api_client/api_client.dart' as dto;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/data/api_shopping_item_repository.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_page.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';

import '../../../core/network/fake_http_adapter.dart';
import '../mocks.dart';

/// `DioException` seperti yang dilempar `ShoppingClient` untuk respons error API.
DioException apiError(int status, Map<String, Object?> body) {
  final options = RequestOptions(path: '/v1/shopping-items');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  final itemDto = dto.ShoppingItem.fromJson(shoppingItemJson);
  late MockShoppingItemRemoteDataSource remote;
  late ApiShoppingItemRepository repository;

  setUp(() {
    remote = MockShoppingItemRemoteDataSource();
    repository = ApiShoppingItemRepository(remote);
  });

  void stubUpdateThrows(DioException error) => when(
    () => remote.update(
      any(),
      name: any(named: 'name'),
      quantity: any(named: 'quantity'),
      isDone: any(named: 'isDone'),
    ),
  ).thenThrow(error);

  group('sukses → Ok berisi entity', () {
    test('list', () async {
      when(() => remote.list(cursor: 'c1', limit: 10)).thenAnswer(
        (_) async => dto.ShoppingItemPage(items: [itemDto], nextCursor: 'c2'),
      );

      expect(
        await repository.list(cursor: 'c1', limit: 10),
        Ok(ShoppingItemPage(items: [testShoppingItem], nextCursor: 'c2')),
      );
    });

    test('create', () async {
      when(() => remote.create(name: 'Telur', quantity: 2))
          .thenAnswer((_) async => itemDto);

      expect(
        await repository.create(name: 'Telur', quantity: 2),
        Ok(testShoppingItem),
      );
    });

    test('update', () async {
      when(() => remote.update(testShoppingItem.id, isDone: false))
          .thenAnswer((_) async => itemDto);

      expect(
        await repository.update(testShoppingItem.id, isDone: false),
        Ok(testShoppingItem),
      );
    });

    test('delete', () async {
      when(() => remote.delete(testShoppingItem.id)).thenAnswer((_) async {});

      expect(
        await repository.delete(testShoppingItem.id),
        const Ok<void>(null),
      );
      verify(() => remote.delete(testShoppingItem.id)).called(1);
    });

    test('clearDone → jumlah barang yang terhapus', () async {
      when(() => remote.clearDone()).thenAnswer(
        (_) async => const dto.ClearDoneShoppingItemsResult(deletedCount: 3),
      );

      expect(await repository.clearDone(), const Ok(3));
    });
  });

  group('filter status dipetakan ke nilai kontrak', () {
    setUp(
      () =>
          when(
            () => remote.list(
              status: any(named: 'status'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer(
            (_) async =>
                const dto.ShoppingItemPage(items: [], nextCursor: null),
          ),
    );

    for (final (status, expected) in [
      (ShoppingItemStatus.all, dto.ShoppingItemStatus.all),
      (ShoppingItemStatus.open, dto.ShoppingItemStatus.open),
      (ShoppingItemStatus.done, dto.ShoppingItemStatus.done),
    ]) {
      test('${status.name} → ${expected.json}', () async {
        await repository.list(status: status);

        verify(() => remote.list(status: expected)).called(1);
      });
    }

    test('tanpa status → tidak dikirim (bawaan API)', () async {
      await repository.list();

      verify(() => remote.list()).called(1);
    });
  });

  group('CONFLICT (nama sudah ada) → Err(conflict)', () {
    final conflict = apiError(409, errorBody('CONFLICT'));
    const failure = Failure(
      FailureCode.conflict,
      message: 'message for CONFLICT',
    );

    test('create', () async {
      when(
        () => remote.create(
          name: any(named: 'name'),
          quantity: any(named: 'quantity'),
        ),
      ).thenThrow(conflict);

      expect(
        await repository.create(name: 'telur'),
        const Err<ShoppingItem>(failure),
      );
    });

    test('update nama', () async {
      stubUpdateThrows(conflict);

      expect(
        await repository.update(testShoppingItem.id, name: 'Susu'),
        const Err<ShoppingItem>(failure),
      );
    });
  });

  group('NOT_FOUND → Err(notFound)', () {
    final notFound = apiError(404, errorBody('NOT_FOUND'));
    const failure = Failure(
      FailureCode.notFound,
      message: 'message for NOT_FOUND',
    );

    test('update', () async {
      stubUpdateThrows(notFound);

      expect(
        await repository.update('lain', isDone: true),
        const Err<ShoppingItem>(failure),
      );
    });

    test('delete', () async {
      when(() => remote.delete(any())).thenThrow(notFound);

      expect(await repository.delete('lain'), const Err<void>(failure));
    });
  });

  group(
    'VALIDATION_ERROR → Err(validation) dengan fieldErrors dari details',
    () {
      test('create dengan nama kosong → fieldErrors.name', () async {
        when(
          () => remote.create(
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
          ),
        ).thenThrow(
          apiError(
            422,
            errorBody(
              'VALIDATION_ERROR',
              details: {
                'name': [
                  {
                    'code': 'too_small',
                    'message':
                        'Too small: expected string to have >=1 characters',
                  },
                ],
              },
            ),
          ),
        );

        final result = await repository.create(name: '');

        expect(
          result,
          const Err<ShoppingItem>(
            Failure(
              FailureCode.validation,
              message: 'message for VALIDATION_ERROR',
              fieldErrors: {
                'name': [
                  FieldIssue(
                    'too_small',
                    'Too small: expected string to have >=1 characters',
                  ),
                ],
              },
            ),
          ),
        );
      });

      test('update tanpa field → fieldErrors._root', () async {
        stubUpdateThrows(
          apiError(
            422,
            errorBody(
              'VALIDATION_ERROR',
              details: {
                '_root': [
                  {
                    'code': 'custom',
                    'message': 'At least one field is required',
                  },
                ],
              },
            ),
          ),
        );

        final result = await repository.update(testShoppingItem.id);

        final failure = (result as Err<ShoppingItem>).failure;
        expect(failure.code, FailureCode.validation);
        expect(failure.fieldErrors.keys, ['_root']);
        expect(failure.fieldErrors['_root']!.single.code, 'custom');
      });
    },
  );

  test('API tidak bisa dihubungi → Err(network)', () async {
    when(() => remote.clearDone()).thenThrow(
      DioException.connectionError(
        requestOptions: RequestOptions(path: '/v1/shopping-items/clear-done'),
        reason: 'Connection refused',
      ),
    );

    final result = await repository.clearDone();

    expect((result as Err<int>).failure.code, FailureCode.network);
  });
}
