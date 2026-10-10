import 'package:firebase_auth/firebase_auth.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/failure_log.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/auth/data/auth_mapper.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';

/// [AuthRepository] di atas Firebase Auth (Auth Emulator bila `USE_EMULATOR=true`, lihat `main.dart`).
///
/// SDK Firebase berperan sebagai data source; `FirebaseAuthException` → `Err` lewat
/// [failureFromFirebaseAuth] dan dicatat [logFailure] (mode debug).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  AuthUser? get currentUser => switch (_auth.currentUser) {
    final User user => authUserFromFirebase(user),
    null => null,
  };

  @override
  Stream<AuthUser?> authUserChanges() => _auth.authStateChanges().map(
    (user) => user == null ? null : authUserFromFirebase(user),
  );

  @override
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  }) => _credential(
    () => _auth.signInWithEmailAndPassword(email: email, password: password),
  );

  @override
  Future<Result<AuthUser>> register({
    required String email,
    required String password,
  }) => _credential(
    () =>
        _auth.createUserWithEmailAndPassword(email: email, password: password),
  );

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Ok(null);
    } on FirebaseAuthException catch (e) {
      return Err(_failure(e));
    }
  }

  Future<Result<AuthUser>> _credential(
    Future<UserCredential> Function() action,
  ) async {
    try {
      final credential = await action();
      return Ok(authUserFromFirebase(credential.user!));
    } on FirebaseAuthException catch (e) {
      return Err(_failure(e));
    }
  }

  Failure _failure(FirebaseAuthException e) {
    final failure = failureFromFirebaseAuth(e);
    logFailure(failure);
    return failure;
  }
}
