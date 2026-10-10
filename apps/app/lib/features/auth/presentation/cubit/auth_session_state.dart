import 'package:equatable/equatable.dart';

import 'package:app/features/auth/domain/entities/auth_user.dart';

/// Status login app, dibaca router untuk redirect rute terlindungi.
sealed class AuthSessionState extends Equatable {
  const AuthSessionState();
}

final class Authenticated extends AuthSessionState {
  const Authenticated(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthSessionState {
  const Unauthenticated();

  @override
  List<Object?> get props => [];
}
