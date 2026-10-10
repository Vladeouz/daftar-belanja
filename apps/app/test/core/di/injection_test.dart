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
import 'package:app/features/shopping/data/api_shopping_item_repository.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';
import 'package:app/features/shopping/domain/usecases/clear_done_shopping_items.dart';
import 'package:app/features/shopping/domain/usecases/create_shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/delete_shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/list_shopping_items.dart';
import 'package:app/features/shopping/domain/usecases/update_shopping_item.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_cubit.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_list_cubit.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  const config = AppConfig(
    apiBaseUrl: 'http://10.0.2.2:3000',
    firebaseProjectId: 'demo-daftar-belanja',
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

  test('mendaftarkan dependency fitur shopping', () {
    expect(
      container<ShoppingItemRepository>(),
      isA<ApiShoppingItemRepository>(),
    );
    expect(
      container<ShoppingItemRepository>(),
      same(container<ShoppingItemRepository>()),
    );
    expect(container<ListShoppingItems>(), isA<ListShoppingItems>());
    expect(container<CreateShoppingItem>(), isA<CreateShoppingItem>());
    expect(container<UpdateShoppingItem>(), isA<UpdateShoppingItem>());
    expect(container<DeleteShoppingItem>(), isA<DeleteShoppingItem>());
    expect(container<ClearDoneShoppingItems>(), isA<ClearDoneShoppingItems>());
    // Cubit halaman: baru setiap diminta (ditutup BlocProvider).
    expect(
      container<ShoppingListCubit>(),
      isNot(same(container<ShoppingListCubit>())),
    );
    expect(
      container<ShoppingItemFormCubit>(),
      isNot(same(container<ShoppingItemFormCubit>())),
    );
  });

  test('memakai GetIt.instance bila container tidak diberikan', () async {
    addTearDown(GetIt.instance.reset);
    configureDependencies(config: config, auth: auth);

    expect(getIt<AppConfig>(), same(config));
  });
}
