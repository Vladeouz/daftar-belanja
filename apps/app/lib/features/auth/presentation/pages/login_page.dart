import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/features/auth/presentation/cubit/auth_form_state.dart';
import 'package:app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:app/features/auth/presentation/widgets/auth_form.dart';
import 'package:app/features/auth/presentation/widgets/auth_scaffold.dart';

/// Halaman login. Butuh [LoginCubit] dari `BlocProvider` (dipasang router).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Masuk',
      children: [
        BlocBuilder<LoginCubit, AuthFormState>(
          builder: (context, state) => AuthForm(
            state: state,
            submitLabel: 'Masuk',
            onSubmit: (email, password) => context.read<LoginCubit>().submit(
              email: email,
              password: password,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go(AppRoutes.register),
          child: const Text('Belum punya akun? Daftar'),
        ),
      ],
    );
  }
}
