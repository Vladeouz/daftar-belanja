import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/usecases/watch_auth_user.dart';

import '../../mocks.dart';

void main() {
  const user = AuthUser(id: 'uid-1', email: 'a@example.com');
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  test('current dari repository.currentUser', () {
    when(() => repository.currentUser).thenReturn(user);
    expect(WatchAuthUser(repository).current, user);

    when(() => repository.currentUser).thenReturn(null);
    expect(WatchAuthUser(repository).current, isNull);
  });

  test('call() meneruskan stream perubahan user', () {
    when(() => repository.authUserChanges())
        .thenAnswer((_) => Stream.fromIterable([user, null]));

    expect(WatchAuthUser(repository)(), emitsInOrder([user, null, emitsDone]));
  });
}
