import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';

void main() {
  String describe(Result<int> result) => switch (result) {
    Ok(:final value) => 'ok $value',
    Err(:final failure) => 'err ${failure.code.name}',
  };

  test('switch pada Result mencakup Ok dan Err', () {
    expect(describe(const Ok(1)), 'ok 1');
    expect(describe(const Err(Failure(FailureCode.notFound))), 'err notFound');
  });

  test('kesetaraan berdasarkan nilai', () {
    expect(const Ok(1), const Ok(1));
    expect(const Ok(1), isNot(const Ok(2)));
    expect(
      const Err<int>(
        Failure(
          FailureCode.validation,
          fieldErrors: {
            'title': [FieldIssue('required', 'Required')],
          },
        ),
      ),
      const Err<int>(
        Failure(
          FailureCode.validation,
          fieldErrors: {
            'title': [FieldIssue('required', 'Required')],
          },
        ),
      ),
    );
  });
}
