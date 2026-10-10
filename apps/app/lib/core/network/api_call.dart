import 'package:dio/dio.dart';

import 'package:app/core/error/result.dart';
import 'package:app/core/network/error_mapper.dart';

/// Menjalankan panggilan `api_client` dan membungkus hasilnya dalam [Result].
///
/// Dipakai implementasi repository di `features/<fitur>/data/`:
///
/// ```dart
/// Future<Result<Note>> get(String id) =>
///     apiCall(() => client.notes.getNote(id: id), map: noteFromDto);
/// ```
///
/// [DioException] dipetakan lewat [failureFromDioException]; exception lain (bug mapper,
/// DTO tidak sesuai) tidak ditangkap agar terlihat saat development dan di test.
Future<Result<R>> apiCall<T, R>(
  Future<T> Function() call, {
  required R Function(T) map,
}) async {
  try {
    return Ok(map(await call()));
  } on DioException catch (exception) {
    return Err(failureFromDioException(exception));
  }
}

/// Seperti [apiCall] tanpa pemetaan, untuk respons kosong (`204`) atau nilai yang sudah final.
Future<Result<T>> apiCallRaw<T>(Future<T> Function() call) =>
    apiCall(call, map: (value) => value);
