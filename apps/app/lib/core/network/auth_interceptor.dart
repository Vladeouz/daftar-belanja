import 'package:dio/dio.dart';

import 'package:app/core/network/token_provider.dart';

/// Menambahkan `Authorization: Bearer <ID token>` ke setiap request bila user login.
///
/// Bila respons `401`, token di-refresh sekali (`forceRefresh`) lalu request diulang satu kali.
/// `401` kedua diteruskan ke pemanggil (menjadi `FailureCode.unauthenticated`).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._tokens, required this._dio});

  final TokenProvider _tokens;

  /// Dio yang sama dengan pemilik interceptor, untuk mengulang request.
  final Dio _dio;

  /// Penanda di `RequestOptions.extra` bahwa request ini adalah pengulangan setelah refresh.
  static const retriedKey = 'authRetried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokens.idToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final canRetry =
        err.response?.statusCode == 401 &&
        options.extra[retriedKey] != true &&
        options.headers.containsKey('Authorization');
    if (!canRetry) {
      return handler.next(err);
    }

    final String? token;
    try {
      token = await _tokens.idToken(forceRefresh: true);
    } on Object {
      return handler.next(err);
    }
    if (token == null) {
      return handler.next(err);
    }

    try {
      final response = await _dio.fetch<Object?>(
        options.copyWith(
          headers: {...options.headers, 'Authorization': 'Bearer $token'},
          extra: {...options.extra, retriedKey: true},
        ),
      );
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
