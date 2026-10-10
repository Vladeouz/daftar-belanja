import 'package:api_client/api_client.dart' as dto;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/notes/data/api_note_repository.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/entities/note_page.dart';

import '../../../core/network/fake_http_adapter.dart';
import '../mocks.dart';

/// `DioException` seperti yang dilempar `NotesClient` untuk respons error API.
DioException apiError(int status, Map<String, Object?> body) {
  final options = RequestOptions(path: '/v1/notes');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  final noteDto = dto.Note.fromJson(noteJson);
  late MockNoteRemoteDataSource remote;
  late ApiNoteRepository repository;

  setUp(() {
    remote = MockNoteRemoteDataSource();
    repository = ApiNoteRepository(remote);
  });

  group('sukses → Ok berisi entity', () {
    test('list', () async {
      when(() => remote.list(cursor: 'c1', limit: 10)).thenAnswer(
        (_) async => dto.NotePage(items: [noteDto], nextCursor: 'c2'),
      );

      expect(
        await repository.list(cursor: 'c1', limit: 10),
        Ok(NotePage(items: [testNote], nextCursor: 'c2')),
      );
    });

    test('get', () async {
      when(() => remote.get(testNote.id)).thenAnswer((_) async => noteDto);

      expect(await repository.get(testNote.id), Ok(testNote));
    });

    test('create', () async {
      when(() => remote.create(title: 'Belanja', body: 'Susu dan roti'))
          .thenAnswer((_) async => noteDto);

      expect(
        await repository.create(title: 'Belanja', body: 'Susu dan roti'),
        Ok(testNote),
      );
    });

    test('update', () async {
      when(() => remote.update(testNote.id, body: 'Susu dan roti'))
          .thenAnswer((_) async => noteDto);

      expect(
        await repository.update(testNote.id, body: 'Susu dan roti'),
        Ok(testNote),
      );
    });

    test('delete', () async {
      when(() => remote.delete(testNote.id)).thenAnswer((_) async {});

      expect(await repository.delete(testNote.id), const Ok<void>(null));
      verify(() => remote.delete(testNote.id)).called(1);
    });
  });

  group('NOT_FOUND → Err(notFound)', () {
    final notFound = apiError(404, errorBody('NOT_FOUND'));
    const failure = Failure(
      FailureCode.notFound,
      message: 'message for NOT_FOUND',
    );

    test('get', () async {
      when(() => remote.get(any())).thenThrow(notFound);

      expect(await repository.get('lain'), const Err<Note>(failure));
    });

    test('update', () async {
      when(
        () => remote.update(
          any(),
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).thenThrow(notFound);

      expect(
        await repository.update('lain', title: 'Judul'),
        const Err<Note>(failure),
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
      test('create dengan judul kosong → fieldErrors.title', () async {
        when(
          () => remote.create(
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        ).thenThrow(
          apiError(
            422,
            errorBody(
              'VALIDATION_ERROR',
              details: {
                'title': [
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

        final result = await repository.create(title: '');

        expect(
          result,
          const Err<Note>(
            Failure(
              FailureCode.validation,
              message: 'message for VALIDATION_ERROR',
              fieldErrors: {
                'title': [
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
        when(
          () => remote.update(
            any(),
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        ).thenThrow(
          apiError(
            422,
            errorBody(
              'VALIDATION_ERROR',
              details: {
                '_root': [
                  {
                    'code': 'custom',
                    'message': 'At least one of title or body is required',
                  },
                ],
              },
            ),
          ),
        );

        final result = await repository.update(testNote.id);

        final failure = (result as Err<Note>).failure;
        expect(failure.code, FailureCode.validation);
        expect(failure.fieldErrors.keys, ['_root']);
        expect(failure.fieldErrors['_root']!.single.code, 'custom');
      });

      test('list dengan cursor rusak → fieldErrors.cursor', () async {
        when(
          () => remote.list(
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          ),
        ).thenThrow(
          apiError(
            422,
            errorBody(
              'VALIDATION_ERROR',
              details: {
                'cursor': [
                  {'code': 'custom', 'message': 'Invalid cursor'},
                ],
              },
            ),
          ),
        );

        final result = await repository.list(cursor: 'xyz');

        expect((result as Err<NotePage>).failure.fieldErrors['cursor'], const [
          FieldIssue('custom', 'Invalid cursor'),
        ]);
      });
    },
  );

  test('API tidak bisa dihubungi → Err(network)', () async {
    when(
      () => remote.list(
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenThrow(
      DioException.connectionError(
        requestOptions: RequestOptions(path: '/v1/notes'),
        reason: 'Connection refused',
      ),
    );

    final result = await repository.list();

    expect((result as Err<NotePage>).failure.code, FailureCode.network);
  });
}
