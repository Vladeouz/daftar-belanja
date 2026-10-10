import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/auth/presentation/cubit/auth_form_state.dart';
import 'package:app/features/auth/presentation/cubit/register_cubit.dart';
import 'package:app/features/auth/presentation/pages/register_page.dart';

import '../../mocks.dart';

void main() {
  late MockRegisterCubit cubit;

  setUp(() {
    cubit = MockRegisterCubit();
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
        home: BlocProvider<RegisterCubit>.value(
          value: cubit,
          child: const RegisterPage(),
        ),
      ),
    );
  }

  testWidgets('mengirim email dan password ke RegisterCubit', (tester) async {
    await pumpPage(tester, const AuthFormIdle());

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'b@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'rahasia');
    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));

    verify(() => cubit.submit(email: 'b@example.com', password: 'rahasia'))
        .called(1);
  });

  testWidgets('email sudah terdaftar → pesan Bahasa Indonesia', (tester) async {
    await pumpPage(
      tester,
      const AuthFormFailed(Failure(FailureCode.emailAlreadyInUse)),
    );

    expect(find.text('Email sudah terdaftar. Silakan masuk.'), findsOneWidget);
    expect(find.text('Sudah punya akun? Masuk'), findsOneWidget);
  });
}
