import 'package:get_it/get_it.dart';

import 'package:app/features/auth/data/firebase_auth_repository.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/domain/usecases/register.dart';
import 'package:app/features/auth/domain/usecases/sign_in.dart';
import 'package:app/features/auth/domain/usecases/sign_out.dart';
import 'package:app/features/auth/domain/usecases/watch_auth_user.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:app/features/auth/presentation/cubit/register_cubit.dart';

/// Dependency fitur auth. Dipanggil dari `configureDependencies` (butuh `FirebaseAuth`).
///
/// [AuthSessionCubit] singleton (status login sepanjang umur app); Cubit form dibuat
/// baru setiap halaman dibuka (`registerFactory`) dan ditutup `BlocProvider`.
void registerAuthDependencies(GetIt c) {
  c
    ..registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository(c()))
    ..registerLazySingleton(() => SignIn(c()))
    ..registerLazySingleton(() => Register(c()))
    ..registerLazySingleton(() => SignOut(c()))
    ..registerLazySingleton(() => WatchAuthUser(c()))
    ..registerLazySingleton(
      () => AuthSessionCubit(watchAuthUser: c(), signOut: c()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerFactory(() => LoginCubit(c()))
    ..registerFactory(() => RegisterCubit(c()));
}
