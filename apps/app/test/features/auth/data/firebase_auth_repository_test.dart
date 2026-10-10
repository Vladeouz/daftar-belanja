import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/auth/data/firebase_auth_repository.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  const authUser = AuthUser(id: 'uid-1', email: 'a@example.com');
  late MockFirebaseAuth auth;
  late MockUser user;
  late FirebaseAuthRepository repository;

  setUp(() {
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => user.email).thenReturn('a@example.com');
    repository = FirebaseAuthRepository(auth);
  });

  MockUserCredential credentialFor(User user) {
    final credential = MockUserCredential();
    when(() => credential.user).thenReturn(user);
    return credential;
  }

  group('currentUser', () {
    test('user Firebase → AuthUser', () {
      when(() => auth.currentUser).thenReturn(user);
      expect(repository.currentUser, authUser);
    });

    test('belum login → null', () {
      when(() => auth.currentUser).thenReturn(null);
      expect(repository.currentUser, isNull);
    });
  });

  test('authUserChanges memetakan authStateChanges', () {
    when(() => auth.authStateChanges())
        .thenAnswer((_) => Stream.fromIterable([null, user, null]));

    expect(
      repository.authUserChanges(),
      emitsInOrder([null, authUser, null, emitsDone]),
    );
  });

  group('signIn', () {
    test('berhasil → Ok(AuthUser)', () async {
      final credential = credentialFor(user);
      when(
        () => auth.signInWithEmailAndPassword(
          email: 'a@example.com',
          password: 'rahasia',
        ),
      ).thenAnswer((_) async => credential);

      expect(
        await repository.signIn(email: 'a@example.com', password: 'rahasia'),
        const Ok(authUser),
      );
    });

    test('password salah → Err(invalidCredentials)', () async {
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      final result = await repository.signIn(
        email: 'a@example.com',
        password: 'salah',
      );

      expect(result, isA<Err<AuthUser>>());
      expect(
        (result as Err<AuthUser>).failure.code,
        FailureCode.invalidCredentials,
      );
    });
  });

  group('register', () {
    test('berhasil → Ok(AuthUser)', () async {
      final credential = credentialFor(user);
      when(
        () => auth.createUserWithEmailAndPassword(
          email: 'a@example.com',
          password: 'rahasia',
        ),
      ).thenAnswer((_) async => credential);

      expect(
        await repository.register(email: 'a@example.com', password: 'rahasia'),
        const Ok(authUser),
      );
    });

    test('email sudah dipakai → Err(emailAlreadyInUse)', () async {
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final result = await repository.register(
        email: 'a@example.com',
        password: 'rahasia',
      );

      expect(
        (result as Err<AuthUser>).failure.code,
        FailureCode.emailAlreadyInUse,
      );
    });
  });

  group('signOut', () {
    test('berhasil → Ok', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});

      expect(await repository.signOut(), const Ok<void>(null));
      verify(() => auth.signOut()).called(1);
    });

    test('FirebaseAuthException → Err', () async {
      when(() => auth.signOut())
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final result = await repository.signOut();

      expect((result as Err<void>).failure.code, FailureCode.network);
    });
  });
}
