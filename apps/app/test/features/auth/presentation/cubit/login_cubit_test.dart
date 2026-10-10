import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/usecases/sign_in.dart';
import 'package:app/features/auth/presentation/cubit/auth_form_state.dart';
import 'package:app/features/auth/presentation/cubit/login_cubit.dart';

class MockSignIn extends Mock implements SignIn {}

void main() {
  const user = AuthUser(id: 'uid-1', email: 'a@example.com');
  const wrongPassword = Failure(FailureCode.invalidCredentials);
  late MockSignIn signIn;

  setUp(() => signIn = MockSignIn());

  void stubSignIn(Future<Result<AuthUser>> Function() answer) => when(
    () => signIn(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) => answer());

  test('state awal AuthFormIdle', () {
    expect(LoginCubit(signIn).state, const AuthFormIdle());
  });

  blocTest<LoginCubit, AuthFormState>(
    'kredensial benar → Submitting lalu Succeeded',
    setUp: () => stubSignIn(() async => const Ok(user)),
    build: () => LoginCubit(signIn),
    act: (cubit) => cubit.submit(email: 'a@example.com', password: 'rahasia'),
    expect: () => const [AuthFormSubmitting(), AuthFormSucceeded()],
    verify: (_) =>
        verify(() => signIn(email: 'a@example.com', password: 'rahasia'))
            .called(1),
  );

  blocTest<LoginCubit, AuthFormState>(
    'password salah → Submitting lalu Failed(invalidCredentials)',
    setUp: () => stubSignIn(() async => const Err(wrongPassword)),
    build: () => LoginCubit(signIn),
    act: (cubit) => cubit.submit(email: 'a@example.com', password: 'salah'),
    expect: () => const [AuthFormSubmitting(), AuthFormFailed(wrongPassword)],
  );

  blocTest<LoginCubit, AuthFormState>(
    'percobaan ulang setelah gagal bisa berhasil',
    setUp: () => stubSignIn(() async => const Ok(user)),
    build: () => LoginCubit(signIn),
    seed: () => const AuthFormFailed(wrongPassword),
    act: (cubit) => cubit.submit(email: 'a@example.com', password: 'rahasia'),
    expect: () => const [AuthFormSubmitting(), AuthFormSucceeded()],
  );

  blocTest<LoginCubit, AuthFormState>(
    'submit kedua saat masih Submitting diabaikan',
    setUp: () {
      final pending = Completer<Result<AuthUser>>();
      stubSignIn(() => pending.future);
      addTearDown(() => pending.complete(const Ok(user)));
    },
    build: () => LoginCubit(signIn),
    act: (cubit) {
      unawaited(cubit.submit(email: 'a@example.com', password: 'rahasia'));
      unawaited(cubit.submit(email: 'a@example.com', password: 'rahasia'));
    },
    expect: () => const [AuthFormSubmitting()],
    verify: (_) => verify(
      () => signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1),
  );

  test('ditutup sebelum hasil tiba → tidak emit setelah close', () async {
    final pending = Completer<Result<AuthUser>>();
    stubSignIn(() => pending.future);
    final cubit = LoginCubit(signIn);

    final submit = cubit.submit(email: 'a@example.com', password: 'rahasia');
    await cubit.close();
    pending.complete(const Ok(user));

    await expectLater(submit, completes);
    expect(cubit.state, const AuthFormSubmitting());
  });
}
