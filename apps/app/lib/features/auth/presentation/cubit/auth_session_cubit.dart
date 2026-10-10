import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/usecases/sign_out.dart';
import 'package:app/features/auth/domain/usecases/watch_auth_user.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_state.dart';

/// Status login sepanjang umur app (singleton). Router me-redirect setiap kali state berubah.
///
/// State awal dari user saat ini; `main.dart` menunggu event pertama `authStateChanges`
/// sebelum `runApp`, sehingga sesi yang tersimpan (web) sudah dipulihkan.
class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit({
    required WatchAuthUser watchAuthUser,
    required this._signOut,
  }) : super(_stateOf(watchAuthUser.current)) {
    _subscription = watchAuthUser().listen((user) => emit(_stateOf(user)));
  }

  final SignOut _signOut;
  late final StreamSubscription<AuthUser?> _subscription;

  /// Logout. State menjadi [Unauthenticated] lewat stream user, bukan langsung di sini.
  Future<Result<void>> signOut() => _signOut();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }

  static AuthSessionState _stateOf(AuthUser? user) =>
      user == null ? const Unauthenticated() : Authenticated(user);
}
