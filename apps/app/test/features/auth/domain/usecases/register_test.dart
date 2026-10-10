import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/usecases/register.dart';

import '../../mocks.dart';

void main() {
  const user = AuthUser(id: 'uid-1', email: 'a@example.com');
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  void stubRegister(Result<AuthUser> result) => when(
    () => repository.register(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) async => result);

  test('meneruskan email yang dirapikan dan password apa adanya', () async {
    stubRegister(const Ok(user));

    final result = await Register(repository)(
      email: ' a@example.com',
      password: 'rahasia',
    );

    expect(result, const Ok(user));
    verify(
      () => repository.register(email: 'a@example.com', password: 'rahasia'),
    ).called(1);
  });

  test('mengembalikan Err dari repository', () async {
    const failure = Failure(FailureCode.emailAlreadyInUse);
    stubRegister(const Err(failure));

    expect(
      await Register(repository)(email: 'a@example.com', password: 'x'),
      const Err<AuthUser>(failure),
    );
  });
}
