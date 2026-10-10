import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/entities/auth_user.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_state.dart';
import 'package:app/features/auth/presentation/widgets/sign_out_button.dart';

import '../../mocks.dart';

void main() {
  late MockAuthSessionCubit session;

  setUp(() {
    session = MockAuthSessionCubit();
    whenListen(
      session,
      const Stream<AuthSessionState>.empty(),
      initialState: const Authenticated(AuthUser(id: 'u', email: 'a@b.c')),
    );
  });

  Future<void> pumpButton(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthSessionCubit>.value(
        value: session,
        child: Scaffold(appBar: AppBar(actions: const [SignOutButton()])),
      ),
    ),
  );

  testWidgets('menekan Keluar memanggil signOut', (tester) async {
    when(() => session.signOut()).thenAnswer((_) async => const Ok(null));
    await pumpButton(tester);

    await tester.tap(find.byTooltip('Keluar'));
    await tester.pump();

    verify(() => session.signOut()).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('logout gagal → SnackBar dengan teks Bahasa Indonesia', (
    tester,
  ) async {
    when(() => session.signOut())
        .thenAnswer((_) async => const Err(Failure(FailureCode.network)));
    await pumpButton(tester);

    await tester.tap(find.byTooltip('Keluar'));
    await tester.pump();

    expect(
      find.text('Tidak dapat terhubung ke server. Periksa koneksi Anda.'),
      findsOneWidget,
    );
  });
}
