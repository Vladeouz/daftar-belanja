import 'package:dio/dio.dart';

import 'package:app/core/network/auth_interceptor.dart';
import 'package:app/core/network/token_provider.dart';

/// Dio untuk `api_client`: base URL dari `AppConfig.apiBaseUrl` dan [AuthInterceptor].
Dio createDio({required String baseUrl, required TokenProvider tokens}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(AuthInterceptor(tokens: tokens, dio: dio));
  return dio;
}
