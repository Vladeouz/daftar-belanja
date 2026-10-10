import 'package:flutter/material.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/l10n/failure_messages.dart';
import 'package:app/features/notes/presentation/cubit/note_form_state.dart';

/// Panjang judul maksimal, sama dengan API (`notes.route.ts`).
const noteTitleMaxLength = 120;

/// Field judul dan isi note dengan tombol simpan.
///
/// Validasi lokal hanya "judul wajib diisi" (sama dengan API, tidak lebih ketat). Error
/// validasi dari API (`failure.fieldErrors`) tampil di field `title`/`body`; kegagalan lain
/// tampil di atas tombol simpan.
class NoteForm extends StatefulWidget {
  const NoteForm({super.key, required this.state, required this.onSave});

  final NoteFormEditing state;
  final void Function(String title, String body) onSave;

  @override
  State<NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<NoteForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.state.note?.title);
  late final _body = TextEditingController(text: widget.state.note?.body);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_title.text, _body.text);
    }
  }

  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Wajib diisi.' : null;

  static String? _fieldError(Failure? failure, String field) {
    final issues = failure?.fieldErrors[field];
    return (issues == null || issues.isEmpty)
        ? null
        : fieldIssueMessage(issues.first);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final failure = state.failure;
    final titleError = _fieldError(failure, 'title');
    final bodyError = _fieldError(failure, 'body');
    // Kegagalan yang tidak bisa ditaruh di field mana pun (jaringan, NOT_FOUND, `_root`).
    final showGeneral =
        failure != null && titleError == null && bodyError == null;
    final saving = state.status == NoteFormStatus.saving;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('note-title'),
            controller: _title,
            enabled: !state.busy,
            decoration: InputDecoration(
              labelText: 'Judul',
              errorText: titleError,
            ),
            maxLength: noteTitleMaxLength,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('note-body'),
            controller: _body,
            enabled: !state.busy,
            decoration: InputDecoration(
              labelText: 'Isi',
              alignLabelWithHint: true,
              errorText: bodyError,
            ),
            keyboardType: TextInputType.multiline,
            minLines: 5,
            maxLines: null,
          ),
          if (showGeneral) ...[
            const SizedBox(height: 16),
            Text(
              failureMessage(failure.code),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.busy ? null : _submit,
            child: saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
