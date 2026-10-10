import 'package:equatable/equatable.dart';

/// User yang login lewat Firebase Auth.
class AuthUser extends Equatable {
  const AuthUser({required this.id, required this.email});

  /// UID Firebase.
  final String id;

  /// `null` bila akun tidak punya email (bukan login email/password).
  final String? email;

  @override
  List<Object?> get props => [id, email];
}
