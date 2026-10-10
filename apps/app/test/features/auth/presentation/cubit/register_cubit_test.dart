import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/usecases/register.dart';
import 'package:app/features/auth/presentation/cubit/auth_form_state.dart';
import 'package:app/features/auth/presentation/cubit/register_cubit.dart';

class MockRegister extends Mock implements Register {}

void main() {
  const user = AuthUser(id: 'uid-1', email: 'a@example.com');
  late MockRegister register;

  setUp(() => register = MockRegister());

  void stubRegister(Result<AuthUser> result) => when(
    () => register(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) async => result);

  test('state awal AuthFormIdle', () {
    expect(RegisterCubit(register).state, const AuthFormIdle());
  });

  blocTest<RegisterCubit, AuthFormState>(
    'berhasil → Submitting lalu Succeeded',
    setUp: () => stubRegister(const Ok(user)),
    build: () => RegisterCubit(register),
    act: (cubit) => cubit.submit(email: 'a@example.com', password: 'rahasia'),
    expect: () => const [AuthFormSubmitting(), AuthFormSucceeded()],
    verify: (_) =>
        verify(() => register(email: 'a@example.com', password: 'rahasia'))
            .called(1),
  );

  blocTest<RegisterCubit, AuthFormState>(
    'email sudah terdaftar → Submitting lalu Failed(emailAlreadyInUse)',
    setUp: () =>
        stubRegister(const Err(Failure(FailureCode.emailAlreadyInUse))),
    build: () => RegisterCubit(register),
    act: (cubit) => cubit.submit(email: 'a@example.com', password: 'rahasia'),
    expect: () => const [
      AuthFormSubmitting(),
      AuthFormFailed(Failure(FailureCode.emailAlreadyInUse)),
    ],
  );

  blocTest<RegisterCubit, AuthFormState>(
    'submit saat masih Submitting diabaikan',
    build: () => RegisterCubit(register),
    seed: () => const AuthFormSubmitting(),
    act: (cubit) => cubit.submit(email: 'a@example.com', password: 'rahasia'),
    expect: () => const <AuthFormState>[],
    verify: (_) => verifyNever(
      () => register(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ),
  );
}
