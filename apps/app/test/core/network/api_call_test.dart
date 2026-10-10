import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/core/network/api_call.dart';

import '../error/debug_print_capture.dart';

void main() {
  test('sukses → Ok berisi hasil map', () async {
    final result = await apiCall(() async => 21, map: (value) => value * 2);

    expect(result, const Ok(42));
  });

  test('DioException → Err berisi Failure hasil pemetaan', () async {
    final result = await apiCall<int, int>(
      () => throw DioException.connectionError(
        requestOptions: RequestOptions(),
        reason: 'down',
      ),
      map: (value) => value,
    );

    expect(result, isA<Err<int>>());
    expect((result as Err<int>).failure.code, FailureCode.network);
  });

  test(
    'DioException → Failure dicatat dengan pesan aslinya (mode debug)',
    () async {
      final printed = captureDebugPrint();

      await apiCall<int, int>(
        () => throw DioException.connectionError(
          requestOptions: RequestOptions(),
          reason: 'down',
        ),
        map: (value) => value,
      );

      expect(printed, hasLength(1));
      expect(printed.single, startsWith('Failure network: '));
      expect(printed.single, contains('down'));
    },
  );

  test('sukses tidak mencatat apa pun', () async {
    final printed = captureDebugPrint();

    await apiCall(() async => 1, map: (value) => value);

    expect(printed, isEmpty);
  });

  test('exception lain tidak ditangkap', () {
    expect(
      apiCall<int, int>(
        () async => 1,
        map: (_) => throw const FormatException('DTO'),
      ),
      throwsFormatException,
    );
  });

  test('apiCallRaw mengembalikan nilai apa adanya', () async {
    expect(await apiCallRaw(() async => 'ok'), const Ok('ok'));
  });
}
