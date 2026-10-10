import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/error/result.dart';
import 'package:app/features/auth/domain/usecases/register.dart';
import 'package:app/features/auth/presentation/cubit/auth_form_state.dart';

class RegisterCubit extends Cubit<AuthFormState> {
  RegisterCubit(this._register) : super(const AuthFormIdle());

  final Register _register;

  Future<void> submit({required String email, required String password}) async {
    if (state is AuthFormSubmitting) return;
    emit(const AuthFormSubmitting());
    final result = await _register(email: email, password: password);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => const AuthFormSucceeded(),
      Err(:final failure) => AuthFormFailed(failure),
    });
  }
}
