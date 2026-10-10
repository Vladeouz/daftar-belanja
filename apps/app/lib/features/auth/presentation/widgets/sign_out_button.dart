import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/error/result.dart';
import 'package:app/core/l10n/failure_messages.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_cubit.dart';

/// Tombol logout untuk `AppBar.actions` di halaman yang dilindungi.
///
/// Membaca [AuthSessionCubit] dari `BlocProvider` (dipasang router untuk rute terlindungi).
/// Setelah logout, router me-redirect ke halaman login.
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  Future<void> _signOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<AuthSessionCubit>().signOut();
    if (result case Err(:final failure)) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(failure.code))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Keluar',
      icon: const Icon(Icons.logout),
      onPressed: () => _signOut(context),
    );
  }
}
