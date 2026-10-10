import 'package:flutter/material.dart';

import 'package:app/core/l10n/failure_messages.dart';
import 'package:app/features/auth/presentation/cubit/auth_form_state.dart';

/// Form email + password yang dipakai halaman login dan daftar.
///
/// Validasi lokal hanya "wajib diisi"; aturan lain (format email, panjang password)
/// dari Firebase dan tampil sebagai pesan kegagalan di bawah form.
class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.state,
    required this.submitLabel,
    required this.onSubmit,
    this.isNewPassword = false,
  });

  final AuthFormState state;
  final String submitLabel;
  final void Function(String email, String password) onSubmit;

  /// `true` di halaman daftar (petunjuk autofill password baru).
  final bool isNewPassword;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_email.text, _password.text);
    }
  }

  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Wajib diisi.' : null;

  @override
  Widget build(BuildContext context) {
    final submitting = widget.state is AuthFormSubmitting;
    final failure = switch (widget.state) {
      AuthFormFailed(:final failure) => failure,
      _ => null,
    };

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('auth-email'),
              controller: _email,
              enabled: !submitting,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('auth-password'),
              controller: _password,
              enabled: !submitting,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              autofillHints: [
                widget.isNewPassword
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: _required,
            ),
            if (failure != null) ...[
              const SizedBox(height: 16),
              Text(
                failureMessage(failure.code),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}
