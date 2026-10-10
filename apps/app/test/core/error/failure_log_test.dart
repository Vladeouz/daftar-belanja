import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/failure_log.dart';

import 'debug_print_capture.dart';

void main() {
  late List<String> printed;

  setUp(() => printed = captureDebugPrint());

  test('mode debug: kode dan pesan asli dicatat', () {
    logFailure(
      const Failure(
        FailureCode.unknown,
        message: 'firebase_auth/unknown: API key not valid',
      ),
      debug: true,
    );

    expect(printed, [
      'Failure unknown: firebase_auth/unknown: API key not valid',
    ]);
  });

  test('mode debug: field error disebut, tanpa pesan bila kosong', () {
    logFailure(
      const Failure(
        FailureCode.validation,
        fieldErrors: {
          'name': [FieldIssue('too_small', 'Too small')],
          '_root': [FieldIssue('custom', 'At least one field')],
        },
      ),
      debug: true,
    );

    expect(printed, ['Failure validation: - (fields: name, _root)']);
  });

  test('mode rilis: tidak mencatat apa pun', () {
    logFailure(
      const Failure(FailureCode.network, message: 'down'),
      debug: false,
    );

    expect(printed, isEmpty);
  });

  test('bawaan mengikuti kDebugMode', () {
    logFailure(const Failure(FailureCode.network, message: 'down'));

    expect(printed, kDebugMode ? ['Failure network: down'] : isEmpty);
  });
}
