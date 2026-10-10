import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/auth/presentation/cubit/auth_form_state.dart';
import 'package:app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:app/features/auth/presentation/pages/login_page.dart';

import '../../mocks.dart';

void main() {
  late MockLoginCubit cubit;

  setUp(() {
    cubit = MockLoginCubit();
    when(
      () => cubit.submit(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester, AuthFormState state) async {
    whenListen(cubit, const Stream<AuthFormState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<LoginCubit>.value(
          value: cubit,
          child: const LoginPage(),
        ),
      ),
    );
  }

  Finder submitButton() => find.widgetWithText(FilledButton, 'Masuk');

  testWidgets('mengirim email dan password ke LoginCubit', (tester) async {
    await pumpPage(tester, const AuthFormIdle());

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'a@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'rahasia');
    await tester.tap(submitButton());

    verify(() => cubit.submit(email: 'a@example.com', password: 'rahasia'))
        .called(1);
  });

  testWidgets('field kosong → "Wajib diisi." dan tidak dikirim', (
    tester,
  ) async {
    await pumpPage(tester, const AuthFormIdle());

    await tester.tap(submitButton());
    await tester.pump();

    expect(find.text('Wajib diisi.'), findsNWidgets(2));
    verifyNever(
      () => cubit.submit(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('password salah → pesan Bahasa Indonesia yang jelas', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const AuthFormFailed(
        Failure(FailureCode.invalidCredentials, message: 'invalid-credential'),
      ),
    );

    expect(find.text('Email atau password salah.'), findsOneWidget);
    expect(find.textContaining('invalid-credential'), findsNothing);
  });

  testWidgets('saat mengirim: tombol nonaktif dan indikator tampil', (
    tester,
  ) async {
    await pumpPage(tester, const AuthFormSubmitting());

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('tautan ke halaman daftar tampil', (tester) async {
    await pumpPage(tester, const AuthFormIdle());

    expect(find.text('Belum punya akun? Daftar'), findsOneWidget);
  });
}
