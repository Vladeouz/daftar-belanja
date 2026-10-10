import 'dart:async';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';

/// [AuthRepository] dalam memori yang meniru Firebase Auth: akun email → password,
/// login/daftar/logout memancarkan perubahan user.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({Map<String, String>? accounts, AuthUser? signedIn})
    : _accounts = {...?accounts},
      _user = signedIn;

  final Map<String, String> _accounts;
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  static AuthUser userFor(String email) =>
      AuthUser(id: 'uid-$email', email: email);

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authUserChanges() => _changes.stream;

  @override
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    if (_accounts[email] != password) {
      return const Err(Failure(FailureCode.invalidCredentials));
    }
    return Ok(_setUser(userFor(email)));
  }

  @override
  Future<Result<AuthUser>> register({
    required String email,
    required String password,
  }) async {
    if (_accounts.containsKey(email)) {
      return const Err(Failure(FailureCode.emailAlreadyInUse));
    }
    _accounts[email] = password;
    return Ok(_setUser(userFor(email)));
  }

  @override
  Future<Result<void>> signOut() async {
    _setUser(null);
    return const Ok(null);
  }

  T _setUser<T extends AuthUser?>(T user) {
    _user = user;
    _changes.add(user);
    return user;
  }
}
