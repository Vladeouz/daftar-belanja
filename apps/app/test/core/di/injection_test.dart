import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/di/injection.dart';
import 'package:app/core/network/auth_interceptor.dart';
import 'package:app/core/network/token_provider.dart';
import 'package:app/features/auth/data/firebase_auth_repository.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:app/features/auth/presentation/cubit/register_cubit.dart';
import 'package:app/features/notes/data/api_note_repository.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';
import 'package:app/features/notes/domain/usecases/create_note.dart';
import 'package:app/features/notes/domain/usecases/delete_note.dart';
import 'package:app/features/notes/domain/usecases/get_note.dart';
import 'package:app/features/notes/domain/usecases/list_notes.dart';
import 'package:app/features/notes/domain/usecases/update_note.dart';
import 'package:app/features/notes/presentation/cubit/note_form_cubit.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_cubit.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  const config = AppConfig(
    apiBaseUrl: 'http://10.0.2.2:3000',
    firebaseProjectId: 'demo-template',
    firebaseApiKey: 'demo-api-key',
    firebaseAppId: '1:000000000000:android:0000000000000000',
    firebaseMessagingSenderId: '000000000000',
    useEmulator: true,
    authEmulatorHost: '10.0.2.2',
    authEmulatorPort: 9099,
  );

  late GetIt container;
  late MockFirebaseAuth auth;

  setUp(() {
    container = GetIt.asNewInstance();
    auth = MockFirebaseAuth();
    configureDependencies(config: config, auth: auth, container: container);
  });

  tearDown(() => container.reset());

  test('mendaftarkan config dan FirebaseAuth yang diberikan', () {
    expect(container<AppConfig>(), same(config));
    expect(container<FirebaseAuth>(), same(auth));
    expect(container<TokenProvider>(), isA<FirebaseTokenProvider>());
  });

  test('Dio memakai apiBaseUrl dan AuthInterceptor', () {
    final dio = container<Dio>();

    expect(dio.options.baseUrl, 'http://10.0.2.2:3000');
    expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
  });

  test('ApiClient dan Dio adalah singleton', () {
    expect(container<ApiClient>(), same(container<ApiClient>()));
    expect(container<Dio>(), same(container<Dio>()));
  });

  test('mendaftarkan dependency fitur auth', () {
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.authStateChanges()).thenAnswer((_) => const Stream.empty());

    expect(container<AuthRepository>(), isA<FirebaseAuthRepository>());
    expect(container<AuthSessionCubit>(), same(container<AuthSessionCubit>()));
    expect(container<LoginCubit>(), isNot(same(container<LoginCubit>())));
    expect(container<RegisterCubit>(), isNot(same(container<RegisterCubit>())));
  });

  test('mendaftarkan dependency fitur notes', () {
    expect(container<NoteRepository>(), isA<ApiNoteRepository>());
    expect(container<NoteRepository>(), same(container<NoteRepository>()));
    expect(container<ListNotes>(), isA<ListNotes>());
    expect(container<GetNote>(), isA<GetNote>());
    expect(container<CreateNote>(), isA<CreateNote>());
    expect(container<UpdateNote>(), isA<UpdateNote>());
    expect(container<DeleteNote>(), isA<DeleteNote>());
  });

  test('Cubit notes dibuat baru setiap halaman dibuka (factory)', () {
    expect(
      container<NotesListCubit>(),
      isNot(same(container<NotesListCubit>())),
    );
    expect(container<NoteFormCubit>(), isNot(same(container<NoteFormCubit>())));
  });

  test('memakai GetIt.instance bila container tidak diberikan', () async {
    addTearDown(GetIt.instance.reset);
    configureDependencies(config: config, auth: auth);

    expect(getIt<AppConfig>(), same(config));
  });
}
