import 'package:firebase_auth/firebase_auth.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';

AuthUser authUserFromFirebase(User user) =>
    AuthUser(id: user.uid, email: user.email);

/// Memetakan `FirebaseAuthException.code` ke [Failure]. Kode yang tidak dikenal → [FailureCode.unknown].
Failure failureFromFirebaseAuth(FirebaseAuthException e) {
  final code = switch (e.code) {
    // Dengan email enumeration protection (bawaan project baru), password salah dan
    // akun tidak ada sama-sama `invalid-credential`; kode lama tetap dipetakan.
    'invalid-credential' ||
    'INVALID_LOGIN_CREDENTIALS' ||
    'wrong-password' ||
    'user-not-found' => FailureCode.invalidCredentials,
    'email-already-in-use' => FailureCode.emailAlreadyInUse,
    'weak-password' => FailureCode.weakPassword,
    'invalid-email' => FailureCode.invalidEmail,
    'too-many-requests' => FailureCode.tooManyRequests,
    'user-disabled' => FailureCode.forbidden,
    'network-request-failed' => FailureCode.network,
    _ => FailureCode.unknown,
  };
  return Failure(code, message: 'firebase_auth/${e.code}: ${e.message}');
}
