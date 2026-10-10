import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';

/// User saat ini beserta perubahannya (login/logout). `null` = belum login.
class WatchAuthUser {
  const WatchAuthUser(this._repository);

  final AuthRepository _repository;

  /// User saat ini, tanpa menunggu stream.
  AuthUser? get current => _repository.currentUser;

  Stream<AuthUser?> call() => _repository.authUserChanges();
}
