import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/domain/usecases/sign_out.dart';
import 'package:app/features/auth/domain/usecases/watch_auth_user.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_state.dart';

class MockWatchAuthUser extends Mock implements WatchAuthUser {}

class MockSignOut extends Mock implements SignOut {}

void main() {
  const user = AuthUser(id: 'uid-1', email: 'a@example.com');
  late MockWatchAuthUser watchAuthUser;
  late MockSignOut signOut;
  late StreamController<AuthUser?> changes;

  setUp(() {
    watchAuthUser = MockWatchAuthUser();
    signOut = MockSignOut();
    changes = StreamController<AuthUser?>();
    when(() => watchAuthUser.current).thenReturn(null);
    when(() => watchAuthUser()).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  AuthSessionCubit build() =>
      AuthSessionCubit(watchAuthUser: watchAuthUser, signOut: signOut);

  test('belum login → state awal Unauthenticated', () {
    expect(build().state, const Unauthenticated());
  });

  test('sudah login (sesi tersimpan) → state awal Authenticated', () {
    when(() => watchAuthUser.current).thenReturn(user);
    expect(build().state, const Authenticated(user));
  });

  blocTest<AuthSessionCubit, AuthSessionState>(
    'mengikuti perubahan user: login lalu logout',
    build: build,
    act: (_) {
      changes
        ..add(user)
        ..add(null);
    },
    expect: () => const [Authenticated(user), Unauthenticated()],
  );

  blocTest<AuthSessionCubit, AuthSessionState>(
    'signOut memanggil use case; state berubah lewat stream, bukan langsung',
    setUp: () {
      when(() => watchAuthUser.current).thenReturn(user);
      when(() => signOut()).thenAnswer((_) async => const Ok(null));
    },
    build: build,
    act: (cubit) async => expect(await cubit.signOut(), const Ok<void>(null)),
    expect: () => const <AuthSessionState>[],
    verify: (_) => verify(() => signOut()).called(1),
  );

  test('signOut gagal → Err diteruskan ke pemanggil', () async {
    const failure = Failure(FailureCode.network);
    when(() => signOut()).thenAnswer((_) async => const Err(failure));

    expect(await build().signOut(), const Err<void>(failure));
  });

  test('close membatalkan langganan stream user', () async {
    final cubit = build();
    expect(changes.hasListener, isTrue);

    await cubit.close();

    expect(changes.hasListener, isFalse);
  });
}
