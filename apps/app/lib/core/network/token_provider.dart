import 'package:firebase_auth/firebase_auth.dart';

/// Sumber ID token untuk header `Authorization`. Port agar interceptor bisa diuji tanpa Firebase.
abstract interface class TokenProvider {
  /// ID token user yang login, atau `null` bila belum login.
  ///
  /// Tanpa [forceRefresh], token yang tersimpan dipakai selama belum kedaluwarsa (Firebase
  /// me-refresh otomatis menjelang kedaluwarsa). [forceRefresh] meminta token baru ke server.
  Future<String?> idToken({bool forceRefresh = false});
}

class FirebaseTokenProvider implements TokenProvider {
  FirebaseTokenProvider(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async =>
      _auth.currentUser?.getIdToken(forceRefresh);
}
