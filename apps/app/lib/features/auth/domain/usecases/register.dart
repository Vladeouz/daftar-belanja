import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';

/// Daftar akun baru dengan email dan password. Email dirapikan (spasi di tepi dibuang).
class Register {
  const Register(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) => _repository.register(email: email.trim(), password: password);
}
