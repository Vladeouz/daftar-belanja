import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/auth/data/auth_mapper.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';

class MockUser extends Mock implements User {}

void main() {
  test('authUserFromFirebase memakai uid dan email', () {
    final user = MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => user.email).thenReturn('a@example.com');

    expect(
      authUserFromFirebase(user),
      const AuthUser(id: 'uid-1', email: 'a@example.com'),
    );
  });

  group('failureFromFirebaseAuth', () {
    const expected = {
      'invalid-credential': FailureCode.invalidCredentials,
      'INVALID_LOGIN_CREDENTIALS': FailureCode.invalidCredentials,
      'wrong-password': FailureCode.invalidCredentials,
      'user-not-found': FailureCode.invalidCredentials,
      'email-already-in-use': FailureCode.emailAlreadyInUse,
      'weak-password': FailureCode.weakPassword,
      'invalid-email': FailureCode.invalidEmail,
      'too-many-requests': FailureCode.tooManyRequests,
      'user-disabled': FailureCode.forbidden,
      'network-request-failed': FailureCode.network,
      'kode-baru': FailureCode.unknown,
    };

    for (final MapEntry(key: code, value: failureCode) in expected.entries) {
      test('$code → $failureCode', () {
        final failure = failureFromFirebaseAuth(
          FirebaseAuthException(code: code, message: 'detail'),
        );

        expect(failure.code, failureCode);
        expect(failure.message, 'firebase_auth/$code: detail');
        expect(failure.fieldErrors, isEmpty);
      });
    }
  });
}
