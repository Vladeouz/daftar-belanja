import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';

/// Login dengan email dan password. Email dirapikan (spasi di tepi dibuang).
class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) => _repository.signIn(email: email.trim(), password: password);
}
