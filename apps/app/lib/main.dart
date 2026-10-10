import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:app/app.dart';
import 'package:app/core/config/app_config.dart';
import 'package:app/core/di/injection.dart';

/// Jalankan dengan `flutter run --dart-define-from-file=config/dev.json`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  // D-04: FirebaseOptions dari config, tanpa `flutterfire configure`.
  await Firebase.initializeApp(options: config.firebaseOptions);
  final auth = FirebaseAuth.instance;
  if (config.useEmulator) {
    // Wajib sebelum operasi Auth apa pun.
    await auth.useAuthEmulator(
      config.authEmulatorHost,
      config.authEmulatorPort,
    );
  }

  // Tunggu sesi tersimpan dipulihkan (web), agar status login awal router benar
  // dan user yang sudah login tidak sempat diarahkan ke halaman login.
  await auth.authStateChanges().first;

  configureDependencies(config: config, auth: auth);
  runApp(const App());
}
