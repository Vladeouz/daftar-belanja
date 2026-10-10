import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/features/auth/presentation/cubit/auth_form_state.dart';
import 'package:app/features/auth/presentation/cubit/register_cubit.dart';
import 'package:app/features/auth/presentation/widgets/auth_form.dart';
import 'package:app/features/auth/presentation/widgets/auth_scaffold.dart';

/// Halaman daftar akun. Butuh [RegisterCubit] dari `BlocProvider` (dipasang router).
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Daftar',
      children: [
        BlocBuilder<RegisterCubit, AuthFormState>(
          builder: (context, state) => AuthForm(
            state: state,
            submitLabel: 'Daftar',
            isNewPassword: true,
            onSubmit: (email, password) => context.read<RegisterCubit>().submit(
              email: email,
              password: password,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text('Sudah punya akun? Masuk'),
        ),
      ],
    );
  }
}
