import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:app/app.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/features/auth/auth_dependencies.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/presentation/pages/login_page.dart';
import 'package:app/features/auth/presentation/pages/register_page.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';
import 'package:app/features/notes/notes_dependencies.dart';

import '../../features/auth/fake_auth_repository.dart';
import '../../features/notes/fake_note_repository.dart';

void main() {
  const email = 'a@example.com';
  const password = 'rahasia';

  late GetIt container;

  /// Wiring fitur auth dan notes yang asli, dengan [FakeAuthRepository] menggantikan
  /// Firebase dan [FakeNoteRepository] menggantikan API.
  void setUpAuth({bool signedIn = false}) {
    container = GetIt.asNewInstance();
    registerAuthDependencies(container);
    registerNotesDependencies(container);
    container
      ..unregister<AuthRepository>()
      ..registerSingleton<AuthRepository>(
        FakeAuthRepository(
          accounts: {email: password},
          signedIn: signedIn ? FakeAuthRepository.userFor(email) : null,
        ),
      )
      ..unregister<NoteRepository>()
      ..registerSingleton<NoteRepository>(FakeNoteRepository());
    addTearDown(container.reset);
  }

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String initialLocation = AppRoutes.home,
  }) async {
    final router = createRouter(
      container: container,
      initialLocation: initialLocation,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(App(router: router));
    await tester.pumpAndSettle();
    return router;
  }

  String pathOf(GoRouter router) =>
      router.routeInformationProvider.value.uri.path;

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String email,
    required String password,
    required String button,
  }) async {
    await tester.enterText(find.byKey(const Key('auth-email')), email);
    await tester.enterText(find.byKey(const Key('auth-password')), password);
    await tester.tap(find.widgetWithText(FilledButton, button));
    await tester.pumpAndSettle();
  }

  group('belum login', () {
    setUp(setUpAuth);

    for (final location in [AppRoutes.home, AppRoutes.notes]) {
      testWidgets('membuka $location (terlindungi) → diarahkan ke login', (
        tester,
      ) async {
        final router = await pumpApp(tester, initialLocation: location);

        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.text('Catatan'), findsNothing);
        expect(pathOf(router), AppRoutes.login);
      });
    }

    testWidgets('rute yang tidak ada juga diarahkan ke login', (tester) async {
      final router = await pumpApp(tester, initialLocation: '/tidak-ada');

      expect(find.byType(LoginPage), findsOneWidget);
      expect(pathOf(router), AppRoutes.login);
    });

    testWidgets('halaman daftar boleh dibuka tanpa login', (tester) async {
      final router = await pumpApp(tester, initialLocation: AppRoutes.register);

      expect(find.byType(RegisterPage), findsOneWidget);
      expect(pathOf(router), AppRoutes.register);
    });

    testWidgets(
      'password salah → pesan jelas; kredensial benar → notes; logout → login',
      (tester) async {
        final router = await pumpApp(tester);

        await fillAndSubmit(
          tester,
          email: email,
          password: 'salah',
          button: 'Masuk',
        );
        expect(find.text('Email atau password salah.'), findsOneWidget);
        expect(pathOf(router), AppRoutes.login);

        await fillAndSubmit(
          tester,
          email: email,
          password: password,
          button: 'Masuk',
        );
        expect(find.text('Catatan'), findsOneWidget);
        expect(pathOf(router), AppRoutes.notes);

        await tester.tap(find.byTooltip('Keluar'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);
        expect(pathOf(router), AppRoutes.login);
      },
    );

    testWidgets('daftar dari halaman login → langsung masuk ke notes', (
      tester,
    ) async {
      final router = await pumpApp(tester);

      await tester.tap(find.text('Belum punya akun? Daftar'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterPage), findsOneWidget);

      await fillAndSubmit(
        tester,
        email: email,
        password: password,
        button: 'Daftar',
      );
      expect(
        find.text('Email sudah terdaftar. Silakan masuk.'),
        findsOneWidget,
      );

      await fillAndSubmit(
        tester,
        email: 'baru@example.com',
        password: password,
        button: 'Daftar',
      );
      expect(find.text('Catatan'), findsOneWidget);
      expect(pathOf(router), AppRoutes.notes);
    });
  });

  group('sudah login', () {
    setUp(() => setUpAuth(signedIn: true));

    testWidgets('App membuka notes dengan locale Indonesia', (tester) async {
      final router = await pumpApp(tester);

      expect(pathOf(router), AppRoutes.notes);
      expect(find.text('Catatan'), findsOneWidget);
      final context = tester.element(find.text('Catatan'));
      expect(Localizations.localeOf(context), const Locale('id'));
      expect(MaterialLocalizations.of(context).okButtonLabel, 'OKE');
    });

    for (final location in AppRoutes.public) {
      testWidgets('membuka $location → diarahkan ke notes', (tester) async {
        final router = await pumpApp(tester, initialLocation: location);

        expect(pathOf(router), AppRoutes.notes);
      });
    }

    testWidgets(
      'rute yang tidak ada → halaman tidak ditemukan, tombol kembali ke beranda',
      (tester) async {
        final router = await pumpApp(tester, initialLocation: '/tidak-ada');

        expect(find.byType(NotFoundPage), findsOneWidget);
        expect(find.text('Halaman tidak ditemukan'), findsOneWidget);

        await tester.tap(find.text('Kembali ke beranda'));
        await tester.pumpAndSettle();

        expect(find.byType(NotFoundPage), findsNothing);
        expect(pathOf(router), AppRoutes.notes);
      },
    );
  });
}
