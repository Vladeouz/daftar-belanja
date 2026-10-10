import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Konfigurasi app dari `--dart-define-from-file=config/<env>.json`.
///
/// Kunci baru ditambahkan bersamaan ke `config/dev.json`, [AppConfig.fromEnvironment],
/// dan [AppConfig.fromMap].
class AppConfig extends Equatable {
  const AppConfig({
    required this.apiBaseUrl,
    required this.firebaseProjectId,
    required this.firebaseApiKey,
    required this.firebaseAppId,
    required this.firebaseMessagingSenderId,
    required this.useEmulator,
    required this.authEmulatorHost,
    required this.authEmulatorPort,
  });

  /// Membaca nilai `--dart-define`. Di Android, host `localhost` diganti `10.0.2.2`.
  factory AppConfig.fromEnvironment() => AppConfig.fromMap(const {
    'API_BASE_URL': String.fromEnvironment('API_BASE_URL'),
    'FIREBASE_PROJECT_ID': String.fromEnvironment('FIREBASE_PROJECT_ID'),
    'FIREBASE_API_KEY': String.fromEnvironment('FIREBASE_API_KEY'),
    'FIREBASE_APP_ID': String.fromEnvironment('FIREBASE_APP_ID'),
    'FIREBASE_MESSAGING_SENDER_ID': String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    ),
    'USE_EMULATOR': String.fromEnvironment('USE_EMULATOR'),
    'AUTH_EMULATOR_HOST': String.fromEnvironment('AUTH_EMULATOR_HOST'),
    'AUTH_EMULATOR_PORT': String.fromEnvironment('AUTH_EMULATOR_PORT'),
  }, isAndroid: isAndroidDevice);

  /// Membuat config dari peta kunci → nilai (string, bool, atau int, seperti isi JSON).
  ///
  /// Melempar [ConfigException] yang menyebut nama kunci bila nilai kosong atau salah.
  factory AppConfig.fromMap(
    Map<String, Object?> values, {
    required bool isAndroid,
  }) {
    String read(String key) {
      final value = values[key]?.toString() ?? '';
      if (value.isEmpty) {
        throw ConfigException(key, 'kosong');
      }
      return value;
    }

    bool readBool(String key) => switch (read(key)) {
      'true' => true,
      'false' => false,
      _ => throw ConfigException(key, 'harus true atau false'),
    };

    int readInt(String key) =>
        int.tryParse(read(key)) ??
        (throw ConfigException(key, 'harus bilangan bulat'));

    final apiBaseUrl = Uri.tryParse(read('API_BASE_URL'));
    if (apiBaseUrl == null ||
        !apiBaseUrl.hasScheme ||
        apiBaseUrl.host.isEmpty) {
      throw const ConfigException(
        'API_BASE_URL',
        'harus URL lengkap, misalnya http://localhost:3000',
      );
    }
    final useEmulator = readBool('USE_EMULATOR');

    return AppConfig(
      apiBaseUrl: apiBaseUrl
          .replace(host: resolveHost(apiBaseUrl.host, isAndroid: isAndroid))
          .toString(),
      firebaseProjectId: read('FIREBASE_PROJECT_ID'),
      firebaseApiKey: read('FIREBASE_API_KEY'),
      firebaseAppId: read('FIREBASE_APP_ID'),
      firebaseMessagingSenderId: read('FIREBASE_MESSAGING_SENDER_ID'),
      useEmulator: useEmulator,
      authEmulatorHost: useEmulator
          ? resolveHost(read('AUTH_EMULATOR_HOST'), isAndroid: isAndroid)
          : '',
      authEmulatorPort: useEmulator ? readInt('AUTH_EMULATOR_PORT') : 0,
    );
  }

  final String apiBaseUrl;
  final String firebaseProjectId;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;

  /// Bila true, Firebase Auth memakai Auth Emulator di [authEmulatorHost]:[authEmulatorPort].
  final bool useEmulator;
  final String authEmulatorHost;
  final int authEmulatorPort;

  FirebaseOptions get firebaseOptions => FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: firebaseAppId,
    messagingSenderId: firebaseMessagingSenderId,
    projectId: firebaseProjectId,
  );

  @override
  List<Object?> get props => [
    apiBaseUrl,
    firebaseProjectId,
    firebaseApiKey,
    firebaseAppId,
    firebaseMessagingSenderId,
    useEmulator,
    authEmulatorHost,
    authEmulatorPort,
  ];
}

/// Android emulator mencapai mesin host lewat `10.0.2.2`, bukan `localhost`.
const androidEmulatorHost = '10.0.2.2';

/// True bila app berjalan di Android (bukan web).
bool get isAndroidDevice =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Mengganti `localhost` dan `127.0.0.1` dengan [androidEmulatorHost] bila [isAndroid].
String resolveHost(String host, {required bool isAndroid}) {
  if (isAndroid && (host == 'localhost' || host == '127.0.0.1')) {
    return androidEmulatorHost;
  }
  return host;
}

class ConfigException implements Exception {
  const ConfigException(this.key, this.problem);

  final String key;
  final String problem;

  @override
  String toString() =>
      'ConfigException: $key $problem. Jalankan dengan --dart-define-from-file=config/dev.json';
}
