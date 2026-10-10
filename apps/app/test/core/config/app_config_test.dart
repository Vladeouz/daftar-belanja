import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/config/app_config.dart';

void main() {
  late Map<String, Object?> devJson;

  setUpAll(() {
    devJson = jsonDecode(
      File('config/dev.json').readAsStringSync(),
    ) as Map<String, Object?>;
  });

  group('AppConfig.fromMap dengan config/dev.json', () {
    test('web/iOS: semua nilai terisi apa adanya', () {
      final config = AppConfig.fromMap(devJson, isAndroid: false);

      expect(
        config,
        const AppConfig(
          apiBaseUrl: 'http://localhost:3000',
          firebaseProjectId: 'demo-template',
          firebaseApiKey: 'demo-api-key',
          firebaseAppId: '1:000000000000:android:0000000000000000',
          firebaseMessagingSenderId: '000000000000',
          useEmulator: true,
          authEmulatorHost: 'localhost',
          authEmulatorPort: 9099,
        ),
      );
      expect(config.firebaseOptions.projectId, 'demo-template');
      expect(config.firebaseOptions.apiKey, 'demo-api-key');
    });

    test(
      'Android: host localhost di API dan Auth Emulator menjadi 10.0.2.2',
      () {
        final config = AppConfig.fromMap(devJson, isAndroid: true);

        expect(config.apiBaseUrl, 'http://10.0.2.2:3000');
        expect(config.authEmulatorHost, '10.0.2.2');
        expect(config.authEmulatorPort, 9099);
      },
    );
  });

  group('AppConfig.fromMap dengan nilai string (--dart-define)', () {
    Map<String, Object?> defines([Map<String, Object?> overrides = const {}]) =>
        {
          for (final MapEntry(:key, :value) in devJson.entries) key: '$value',
          ...overrides,
        };

    test('bool dan int dibaca dari string', () {
      final config = AppConfig.fromMap(defines(), isAndroid: false);

      expect(config.useEmulator, isTrue);
      expect(config.authEmulatorPort, 9099);
    });

    test('nilai kosong → ConfigException yang menyebut nama kunci', () {
      expect(
        () => AppConfig.fromMap(
          defines({'FIREBASE_API_KEY': ''}),
          isAndroid: false,
        ),
        throwsA(
          isA<ConfigException>()
              .having((e) => e.key, 'key', 'FIREBASE_API_KEY')
              .having(
                (e) => '$e',
                'toString',
                contains('--dart-define-from-file'),
              ),
        ),
      );
    });

    test('kunci tidak ada → ConfigException', () {
      final values = defines()..remove('API_BASE_URL');
      expect(
        () => AppConfig.fromMap(values, isAndroid: false),
        throwsA(
          isA<ConfigException>().having((e) => e.key, 'key', 'API_BASE_URL'),
        ),
      );
    });

    test('USE_EMULATOR bukan true/false → ConfigException', () {
      expect(
        () => AppConfig.fromMap(
          defines({'USE_EMULATOR': 'ya'}),
          isAndroid: false,
        ),
        throwsA(
          isA<ConfigException>().having((e) => e.key, 'key', 'USE_EMULATOR'),
        ),
      );
    });

    test('AUTH_EMULATOR_PORT bukan angka → ConfigException', () {
      expect(
        () => AppConfig.fromMap(
          defines({'AUTH_EMULATOR_PORT': 'abc'}),
          isAndroid: false,
        ),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.key,
            'key',
            'AUTH_EMULATOR_PORT',
          ),
        ),
      );
    });

    test('API_BASE_URL bukan URL lengkap → ConfigException', () {
      expect(
        () => AppConfig.fromMap(
          defines({'API_BASE_URL': 'localhost:3000'}),
          isAndroid: false,
        ),
        throwsA(
          isA<ConfigException>().having((e) => e.key, 'key', 'API_BASE_URL'),
        ),
      );
    });

    test('USE_EMULATOR=false → host dan port emulator tidak wajib', () {
      final values = defines({'USE_EMULATOR': 'false'})
        ..remove('AUTH_EMULATOR_HOST')
        ..remove('AUTH_EMULATOR_PORT');

      final config = AppConfig.fromMap(values, isAndroid: true);

      expect(config.useEmulator, isFalse);
      expect(config.authEmulatorHost, isEmpty);
    });

    test('host selain localhost tidak diganti di Android', () {
      final config = AppConfig.fromMap(
        defines({
          'API_BASE_URL': 'https://api.example.com',
          'AUTH_EMULATOR_HOST': '192.168.1.5',
        }),
        isAndroid: true,
      );

      expect(config.apiBaseUrl, 'https://api.example.com');
      expect(config.authEmulatorHost, '192.168.1.5');
    });
  });

  group('resolveHost', () {
    test('Android: localhost dan 127.0.0.1 → 10.0.2.2', () {
      expect(resolveHost('localhost', isAndroid: true), androidEmulatorHost);
      expect(resolveHost('127.0.0.1', isAndroid: true), androidEmulatorHost);
    });

    test('bukan Android: tidak berubah', () {
      expect(resolveHost('localhost', isAndroid: false), 'localhost');
      expect(resolveHost('127.0.0.1', isAndroid: false), '127.0.0.1');
    });
  });

  test(
    'AppConfig.fromEnvironment tanpa --dart-define gagal dengan pesan jelas',
    () {
      expect(AppConfig.fromEnvironment, throwsA(isA<ConfigException>()));
    },
  );
}
