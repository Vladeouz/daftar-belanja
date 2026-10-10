import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';

import 'package:app/core/error/failure.dart';

/// Memetakan `ErrorCode` dari kontrak API ke [FailureCode].
///
/// `switch` sengaja tanpa `default`: kode baru di kontrak membuat `flutter analyze` gagal
/// sampai pemetaannya (dan teksnya di `failure_messages.dart`) ditambahkan.
FailureCode failureCodeOf(ErrorCode code) => switch (code) {
  ErrorCode.badRequest => FailureCode.badRequest,
  ErrorCode.unauthenticated => FailureCode.unauthenticated,
  ErrorCode.forbidden => FailureCode.forbidden,
  ErrorCode.notFound => FailureCode.notFound,
  ErrorCode.conflict => FailureCode.conflict,
  ErrorCode.validationError => FailureCode.validation,
  ErrorCode.internalError => FailureCode.internal,
  ErrorCode.$unknown => FailureCode.unknown,
};

/// Memetakan [DioException] ke [Failure].
///
/// Respons dengan body error standar (`{ error: { code, message, details? } }`) memakai `code`
/// dan `details`-nya; timeout dan gagal koneksi menjadi [FailureCode.network]; sisanya
/// [FailureCode.unknown].
Failure failureFromDioException(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return Failure(FailureCode.network, message: exception.message);
    case DioExceptionType.badResponse:
      final body = _readErrorBody(exception.response?.data);
      if (body == null) {
        return Failure(
          FailureCode.unknown,
          message: 'HTTP ${exception.response?.statusCode} without error body',
        );
      }
      return Failure(
        failureCodeOf(body.error.code),
        message: body.error.message,
        fieldErrors: {
          for (final MapEntry(:key, :value)
              in (body.error.details ?? {}).entries)
            key: [
              for (final issue in value) FieldIssue(issue.code, issue.message),
            ],
        },
      );
    default:
      return Failure(
        FailureCode.unknown,
        message: exception.message ?? '${exception.error}',
      );
  }
}

ErrorBody? _readErrorBody(Object? data) {
  if (data is! Map<String, Object?> || data['error'] is! Map) {
    return null;
  }
  try {
    return ErrorBody.fromJson(data);
  } on Object {
    return null;
  }
}
