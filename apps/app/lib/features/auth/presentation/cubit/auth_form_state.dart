import 'package:equatable/equatable.dart';

import 'package:app/core/error/failure.dart';

/// State form login dan daftar (`LoginCubit`, `RegisterCubit`).
sealed class AuthFormState extends Equatable {
  const AuthFormState();

  @override
  List<Object?> get props => [];
}

final class AuthFormIdle extends AuthFormState {
  const AuthFormIdle();
}

final class AuthFormSubmitting extends AuthFormState {
  const AuthFormSubmitting();
}

final class AuthFormFailed extends AuthFormState {
  const AuthFormFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Berhasil. Perpindahan halaman dilakukan router saat `AuthSessionCubit` menjadi `Authenticated`.
final class AuthFormSucceeded extends AuthFormState {
  const AuthFormSucceeded();
}
