import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/usecases/sign_out.dart';

import '../../mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  test('memanggil repository.signOut dan meneruskan Ok', () async {
    when(() => repository.signOut()).thenAnswer((_) async => const Ok(null));

    expect(await SignOut(repository)(), const Ok<void>(null));
    verify(() => repository.signOut()).called(1);
  });

  test('meneruskan Err dari repository', () async {
    const failure = Failure(FailureCode.network);
    when(() => repository.signOut())
        .thenAnswer((_) async => const Err(failure));

    expect(await SignOut(repository)(), const Err<void>(failure));
  });
}
