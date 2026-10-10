import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/presentation/cubit/auth_form_state.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_state.dart';
import 'package:app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:app/features/auth/presentation/cubit/register_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLoginCubit extends MockCubit<AuthFormState> implements LoginCubit {}

class MockRegisterCubit extends MockCubit<AuthFormState>
    implements RegisterCubit {}

class MockAuthSessionCubit extends MockCubit<AuthSessionState>
    implements AuthSessionCubit {}
