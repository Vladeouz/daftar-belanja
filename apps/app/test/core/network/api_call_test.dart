import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/core/network/api_call.dart';

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
