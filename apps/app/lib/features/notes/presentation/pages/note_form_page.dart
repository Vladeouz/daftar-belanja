import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:app/features/notes/presentation/cubit/note_form_cubit.dart';
import 'package:app/features/notes/presentation/cubit/note_form_state.dart';
import 'package:app/features/notes/presentation/widgets/failure_view.dart';
import 'package:app/features/notes/presentation/widgets/note_form.dart';

/// Halaman buat ([noteId] `null`) atau ubah note. Butuh [NoteFormCubit] dari `BlocProvider`
/// (dipasang router).
///
/// Setelah tersimpan atau terhapus, halaman ditutup dengan `context.pop(state)` sehingga
/// halaman daftar menerima `NoteFormSaved`/`NoteFormDeleted`.
class NoteFormPage extends StatelessWidget {
  const NoteFormPage({super.key, this.noteId});

  final String? noteId;

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<NoteFormCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text('Catatan yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.delete();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NoteFormCubit, NoteFormState>(
      listenWhen: (_, state) =>
          state is NoteFormSaved || state is NoteFormDeleted,
      listener: (context, state) => context.pop(state),
      // Form tetap tampil selama halaman ditutup.
      buildWhen: (_, state) =>
          state is! NoteFormSaved && state is! NoteFormDeleted,
      builder: (context, state) {
        final editing = state is NoteFormEditing ? state : null;
        return Scaffold(
          appBar: AppBar(
            title: Text(noteId == null ? 'Catatan baru' : 'Ubah catatan'),
            actions: [
              if (editing != null && !editing.isNew)
                IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: editing.busy
                      ? null
                      : () => _confirmDelete(context),
                ),
              const SignOutButton(),
            ],
          ),
          body: switch (state) {
            NoteFormLoadFailed(:final failure) => FailureView(
              failure: failure,
              onRetry: () => context.read<NoteFormCubit>().load(noteId!),
            ),
            NoteFormEditing() => Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: NoteForm(
                    state: state,
                    onSave: (title, body) => context.read<NoteFormCubit>().save(
                      title: title,
                      body: body,
                    ),
                  ),
                ),
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
    );
  }
}
