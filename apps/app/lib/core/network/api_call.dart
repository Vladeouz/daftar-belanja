import 'package:dio/dio.dart';

import 'package:app/core/error/failure_log.dart';
import 'package:app/core/error/result.dart';
import 'package:app/core/network/error_mapper.dart';

/// Menjalankan panggilan `api_client` dan membungkus hasilnya dalam [Result].
///
/// Dipakai implementasi repository di `features/<fitur>/data/`:
///
/// ```dart
/// Future<Result<ShoppingItem>> create({required String name}) =>
///     apiCall(() => _remote.create(name: name), map: shoppingItemFromDto);
/// ```
///
/// [DioException] dipetakan lewat [failureFromDioException] dan dicatat [logFailure] (mode
/// debug); exception lain (bug mapper, DTO tidak sesuai) tidak ditangkap agar terlihat saat
/// development dan di test.
Future<Result<R>> apiCall<T, R>(
  Future<T> Function() call, {
  required R Function(T) map,
}) async {
  try {
    return Ok(map(await call()));
  } on DioException catch (exception) {
    final failure = failureFromDioException(exception);
    logFailure(failure);
    return Err(failure);
  }
}

/// Seperti [apiCall] tanpa pemetaan, untuk respons kosong (`204`) atau nilai yang sudah final.
Future<Result<T>> apiCallRaw<T>(Future<T> Function() call) =>
    apiCall(call, map: (value) => value);
