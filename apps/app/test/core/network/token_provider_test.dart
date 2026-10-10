import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/network/token_provider.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth auth;
  late FirebaseTokenProvider provider;

  setUp(() {
    auth = MockFirebaseAuth();
    provider = FirebaseTokenProvider(auth);
  });

  test('belum login → null', () async {
    when(() => auth.currentUser).thenReturn(null);

    expect(await provider.idToken(), isNull);
  });

  test('login → ID token user, tanpa paksa refresh', () async {
    final user = MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken(false)).thenAnswer((_) async => 'cached');

    expect(await provider.idToken(), 'cached');
  });

  test('forceRefresh meneruskan permintaan token baru ke Firebase', () async {
    final user = MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken(true)).thenAnswer((_) async => 'fresh');

    expect(await provider.idToken(forceRefresh: true), 'fresh');
    verify(() => user.getIdToken(true)).called(1);
  });
}
