import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/network/create_dio.dart';
import 'package:app/core/network/token_provider.dart';
import 'package:app/features/auth/auth_dependencies.dart';
import 'package:app/features/notes/notes_dependencies.dart';

/// Container dependency app. Widget dan Cubit mengambil dependency lewat konstruktor;
/// `getIt` hanya dipanggil di composition root (`main.dart`, router, `registerXxxDependencies`).
final getIt = GetIt.instance;

/// Mendaftarkan dependency core, lalu dependency setiap fitur.
///
/// Fitur mendaftarkan dependency-nya sendiri lewat `registerXxxDependencies(GetIt container)`
/// di `features/<fitur>/<fitur>_dependencies.dart`, lalu dipanggil di akhir fungsi ini.
/// [auth] diberikan dari luar agar test bisa memakai mock tanpa `Firebase.initializeApp`.
void configureDependencies({
  required AppConfig config,
  required FirebaseAuth auth,
  GetIt? container,
}) {
  final c = container ?? getIt;
  c
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<FirebaseAuth>(auth)
    ..registerLazySingleton<TokenProvider>(() => FirebaseTokenProvider(c()))
    ..registerLazySingleton<Dio>(
      () => createDio(baseUrl: config.apiBaseUrl, tokens: c()),
    )
    ..registerLazySingleton<ApiClient>(() => ApiClient(c()));

  registerAuthDependencies(c);
  registerNotesDependencies(c);
}
