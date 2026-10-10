import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/usecases/sign_in.dart';
import 'package:app/features/auth/presentation/cubit/auth_form_state.dart';

class LoginCubit extends Cubit<AuthFormState> {
  LoginCubit(this._signIn) : super(const AuthFormIdle());

  final SignIn _signIn;

  Future<void> submit({required String email, required String password}) async {
    if (state is AuthFormSubmitting) return;
    emit(const AuthFormSubmitting());
    final result = await _signIn(email: email, password: password);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => const AuthFormSucceeded(),
      Err(:final failure) => AuthFormFailed(failure),
    });
  }
}
