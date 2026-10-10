import 'package:equatable/equatable.dart';

/// Jenis kegagalan yang dikenal app. Nilai API mengikuti `ErrorCode` (PRD bagian 5);
/// [network] dan [unknown] khusus app.
///
/// Teks untuk user diambil lewat `failureMessage()` di `core/l10n/failure_messages.dart`.
enum FailureCode {
  badRequest,
  unauthenticated,
  forbidden,
  notFound,
  conflict,
  validation,
  internal,

  /// Server tidak bisa dihubungi atau koneksi terputus/timeout.
  network,

  /// Kode yang belum dikenal app, atau respons yang tidak bisa dibaca.
  unknown,

  // Firebase Auth (fitur auth), bukan dari API.

  /// Email atau password salah, atau akun tidak ada.
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  tooManyRequests,
}

/// Kegagalan yang dibawa `Err`. Kelas Dart murni, tanpa dio atau DTO, agar bisa dipakai domain.
class Failure extends Equatable {
  const Failure(this.code, {this.message, this.fieldErrors = const {}});

  final FailureCode code;

  /// Pesan bahasa Inggris untuk developer (log). Tidak ditampilkan ke user.
  final String? message;

  /// Hanya untuk [FailureCode.validation]: path field (`title`, `items.0.name`, `_root`) → issue.
  final Map<String, List<FieldIssue>> fieldErrors;

  @override
  List<Object?> get props => [code, message, fieldErrors];
}

/// Satu issue validasi dari `details` (kode issue Zod atau `required`).
class FieldIssue extends Equatable {
  const FieldIssue(this.code, this.message);

  final String code;

  /// Pesan bahasa Inggris dari server. Teks untuk user lewat `fieldIssueMessage()`.
  final String message;

  @override
  List<Object?> get props => [code, message];
}
