import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/network/error_mapper.dart';

import 'fake_http_adapter.dart';

/// Menjalankan request ke adapter palsu dan mengembalikan [DioException]-nya.
Future<DioException> dioErrorFor(
  ResponseBody Function(RequestOptions) respond,
) async {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
    ..httpClientAdapter = FakeHttpAdapter(respond);
  try {
    await dio.get<Object?>('/v1/notes');
  } on DioException catch (e) {
    return e;
  }
  fail('request seharusnya gagal');
}

void main() {
  group('failureCodeOf', () {
    const expected = {
      ErrorCode.badRequest: FailureCode.badRequest,
      ErrorCode.unauthenticated: FailureCode.unauthenticated,
      ErrorCode.forbidden: FailureCode.forbidden,
      ErrorCode.notFound: FailureCode.notFound,
      ErrorCode.conflict: FailureCode.conflict,
      ErrorCode.validationError: FailureCode.validation,
      ErrorCode.internalError: FailureCode.internal,
      ErrorCode.$unknown: FailureCode.unknown,
    };

    test('setiap ErrorCode kontrak punya pemetaan', () {
      expect(expected.keys, unorderedEquals(ErrorCode.values));
    });

    for (final MapEntry(key: code, value: failureCode) in expected.entries) {
      test(
        '$code → $failureCode',
        () => expect(failureCodeOf(code), failureCode),
      );
    }
  });

  group('failureFromDioException', () {
    test(
      'respons error standar → Failure dengan code dan message server',
      () async {
        final error = await dioErrorFor(
          (_) => jsonResponse(errorBody('NOT_FOUND'), 404),
        );

        expect(
          failureFromDioException(error),
          const Failure(FailureCode.notFound, message: 'message for NOT_FOUND'),
        );
      },
    );

    test(
      'setiap ErrorCode dari server dipetakan lewat body, bukan status HTTP',
      () async {
        for (final code in ErrorCode.$valuesDefined) {
          final error = await dioErrorFor(
            (_) => jsonResponse(errorBody(code.json!), 400),
          );
          expect(
            failureFromDioException(error).code,
            failureCodeOf(code),
            reason: code.json,
          );
        }
      },
    );

    test('VALIDATION_ERROR → fieldErrors berisi details (path bersarang dan _root)', () async {
      final error = await dioErrorFor(
        (_) => jsonResponse(
          errorBody(
            'VALIDATION_ERROR',
            details: {
              'title': [
                {'code': 'required', 'message': 'Required'},
              ],
              'items.0.name': [
                {'code': 'too_small', 'message': 'Too small'},
                {'code': 'invalid_format', 'message': 'Invalid'},
              ],
              '_root': [
                {'code': 'custom', 'message': 'At least one field'},
              ],
            },
          ),
          422,
        ),
      );

      final failure = failureFromDioException(error);

      expect(failure.code, FailureCode.validation);
      expect(failure.fieldErrors, {
        'title': [const FieldIssue('required', 'Required')],
        'items.0.name': [
          const FieldIssue('too_small', 'Too small'),
          const FieldIssue('invalid_format', 'Invalid'),
        ],
        '_root': [const FieldIssue('custom', 'At least one field')],
      });
    });

    test('code yang belum dikenal app → FailureCode.unknown', () async {
      final error = await dioErrorFor(
        (_) => jsonResponse(errorBody('RATE_LIMITED'), 429),
      );

      expect(failureFromDioException(error).code, FailureCode.unknown);
    });

    test('respons tanpa body error standar → FailureCode.unknown dengan status di message', () async {
      final error = await dioErrorFor(
        (_) => ResponseBody.fromString('Bad Gateway', 502),
      );

      expect(
        failureFromDioException(error),
        const Failure(
          FailureCode.unknown,
          message: 'HTTP 502 without error body',
        ),
      );
    });

    test('body error dengan bentuk salah → FailureCode.unknown', () async {
      final error = await dioErrorFor(
        (_) => jsonResponse({
          'error': {'code': 42},
        }, 500),
      );

      expect(failureFromDioException(error).code, FailureCode.unknown);
    });

    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('$type → FailureCode.network', () {
        final error = DioException(
          requestOptions: RequestOptions(),
          type: type,
        );
        expect(failureFromDioException(error).code, FailureCode.network);
      });
    }

    for (final type in [DioExceptionType.cancel, DioExceptionType.unknown]) {
      test('$type → FailureCode.unknown', () {
        final error = DioException(
          requestOptions: RequestOptions(),
          type: type,
        );
        expect(failureFromDioException(error).code, FailureCode.unknown);
      });
    }
  });
}
