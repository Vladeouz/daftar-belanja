import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';

/// Autentikasi email dan password. Implementasi: `FirebaseAuthRepository`.
abstract interface class AuthRepository {
  /// User yang login saat ini, atau `null`.
  AuthUser? get currentUser;

  /// Memancarkan user setiap kali login/logout (`null` = belum login).
  Stream<AuthUser?> authUserChanges();

  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  });

  /// Membuat akun baru; user langsung login bila berhasil.
  Future<Result<AuthUser>> register({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();
}
