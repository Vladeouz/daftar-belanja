import 'package:api_client/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/l10n/failure_messages.dart';
import 'package:app/core/network/error_mapper.dart';

void main() {
  group('failureMessage', () {
    test('setiap ErrorCode kontrak punya teks Bahasa Indonesia sendiri, bukan teks umum', () {
      final messages = {
        for (final code in ErrorCode.$valuesDefined)
          code: failureMessage(failureCodeOf(code)),
      };

      expect(messages, {
        ErrorCode.badRequest: 'Permintaan tidak dapat diproses.',
        ErrorCode.unauthenticated:
            'Sesi Anda telah berakhir. Silakan masuk kembali.',
        ErrorCode.forbidden:
            'Anda tidak memiliki akses untuk melakukan tindakan ini.',
        ErrorCode.notFound: 'Data tidak ditemukan.',
        ErrorCode.conflict: 'Data bertentangan dengan data yang sudah ada.',
        ErrorCode.validationError: 'Periksa kembali isian Anda.',
        ErrorCode.internalError:
            'Terjadi kesalahan di server. Silakan coba lagi nanti.',
      });
      expect(messages.values, isNot(contains(genericFailureMessage)));
      expect(
        messages.values.toSet(),
        hasLength(messages.length),
        reason: 'teks tidak boleh kembar',
      );
    });

    test('kode yang belum dikenal memakai teks umum sebagai cadangan', () {
      expect(
        failureMessage(failureCodeOf(ErrorCode.$unknown)),
        genericFailureMessage,
      );
      expect(failureMessage(FailureCode.unknown), genericFailureMessage);
    });

    test(
      'setiap FailureCode selain unknown punya teks sendiri yang tidak kembar',
      () {
        final codes = FailureCode.values.where((c) => c != FailureCode.unknown);
        final messages = codes.map(failureMessage).toList();

        expect(messages, isNot(contains(genericFailureMessage)));
        expect(messages.toSet(), hasLength(messages.length));
      },
    );

    test('kegagalan Firebase Auth punya teks sendiri', () {
      expect(
        failureMessage(FailureCode.invalidCredentials),
        'Email atau password salah.',
      );
      expect(
        failureMessage(FailureCode.emailAlreadyInUse),
        'Email sudah terdaftar. Silakan masuk.',
      );
    });

    test('kegagalan jaringan punya teks sendiri', () {
      expect(
        failureMessage(FailureCode.network),
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    });
  });

  group('fieldIssueMessage', () {
    const expected = {
      'required': 'Wajib diisi.',
      'too_small': 'Terlalu pendek.',
      'too_big': 'Terlalu panjang.',
      'invalid_type': 'Jenis isian tidak sesuai.',
      'invalid_format': 'Format tidak valid.',
      'invalid_string': 'Format tidak valid.',
      'custom': 'Isian tidak valid.',
      'kode_baru': 'Isian tidak valid.',
    };

    for (final MapEntry(key: code, value: text) in expected.entries) {
      test(
        '$code → $text',
        () => expect(fieldIssueMessage(FieldIssue(code, 'x')), text),
      );
    }
  });
}
