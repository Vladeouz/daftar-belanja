import 'package:app/core/error/failure.dart';

/// Teks umum, dipakai bila kode kegagalan atau issue tidak punya teks khusus.
const genericFailureMessage = 'Terjadi kesalahan. Silakan coba lagi.';

/// Teks Bahasa Indonesia untuk user dari [FailureCode] (D-03: server hanya mengirim `code`).
String failureMessage(FailureCode code) => switch (code) {
  FailureCode.badRequest => 'Permintaan tidak dapat diproses.',
  FailureCode.unauthenticated =>
    'Sesi Anda telah berakhir. Silakan masuk kembali.',
  FailureCode.forbidden =>
    'Anda tidak memiliki akses untuk melakukan tindakan ini.',
  FailureCode.notFound => 'Data tidak ditemukan.',
  FailureCode.conflict => 'Data bertentangan dengan data yang sudah ada.',
  FailureCode.validation => 'Periksa kembali isian Anda.',
  FailureCode.internal =>
    'Terjadi kesalahan di server. Silakan coba lagi nanti.',
  FailureCode.network =>
    'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
  FailureCode.unknown => genericFailureMessage,
  FailureCode.invalidCredentials => 'Email atau password salah.',
  FailureCode.emailAlreadyInUse => 'Email sudah terdaftar. Silakan masuk.',
  FailureCode.weakPassword =>
    'Password terlalu lemah. Gunakan minimal 6 karakter.',
  FailureCode.invalidEmail => 'Format email tidak valid.',
  FailureCode.tooManyRequests =>
    'Terlalu banyak percobaan. Silakan coba lagi nanti.',
};

/// Teks Bahasa Indonesia untuk satu issue validasi field (kode issue Zod atau `required`).
String fieldIssueMessage(FieldIssue issue) => switch (issue.code) {
  'required' => 'Wajib diisi.',
  'too_small' => 'Terlalu pendek.',
  'too_big' => 'Terlalu panjang.',
  'invalid_type' => 'Jenis isian tidak sesuai.',
  'invalid_format' || 'invalid_string' => 'Format tidak valid.',
  _ => 'Isian tidak valid.',
};
