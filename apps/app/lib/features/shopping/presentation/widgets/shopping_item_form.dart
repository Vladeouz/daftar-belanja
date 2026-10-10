import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/core/l10n/failure_messages.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_state.dart';

/// Panjang nama maksimal, sama dengan API (`shopping-items.route.ts`).
const shoppingItemNameMaxLength = 80;

/// Jumlah digit maksimal; API menerima 1–999.
const shoppingItemQuantityMaxDigits = 3;

/// Teks di field nama bila API menjawab `CONFLICT` (nama sudah ada, FR-05).
const shoppingItemNameConflictMessage = 'Barang ini sudah ada di daftar.';

/// Field nama dan jumlah barang dengan tombol simpan.
///
/// Validasi lokal hanya "nama wajib diisi" dan jumlah berupa angka (sama dengan API, tidak
/// lebih ketat); batas 1–999 ditegakkan API. Nama yang sudah ada (`CONFLICT`) dan error
/// validasi API (`failure.fieldErrors`) tampil di field-nya; kegagalan lain tampil di atas
/// tombol simpan.
class ShoppingItemForm extends StatefulWidget {
  const ShoppingItemForm({
    super.key,
    required this.state,
    required this.onSave,
  });

  final ShoppingItemFormEditing state;

  /// [quantity] `null` bila field jumlah dikosongkan.
  final void Function(String name, int? quantity) onSave;

  @override
  State<ShoppingItemForm> createState() => _ShoppingItemFormState();
}

class _ShoppingItemFormState extends State<ShoppingItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.state.item?.name);
  late final _quantity = TextEditingController(
    text: '${widget.state.item?.quantity ?? 1}',
  );

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_name.text, int.tryParse(_quantity.text));
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
    final nameError = failure?.code == FailureCode.conflict
        ? shoppingItemNameConflictMessage
        : _fieldError(failure, 'name');
    final quantityError = _fieldError(failure, 'quantity');
    // Kegagalan yang tidak bisa ditaruh di field mana pun (jaringan, NOT_FOUND, `_root`).
    final showGeneral =
        failure != null && nameError == null && quantityError == null;
    final saving = state.status == ShoppingItemFormStatus.saving;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('shopping-item-name'),
            controller: _name,
            enabled: !state.busy,
            autofocus: state.isNew,
            decoration: InputDecoration(
              labelText: 'Nama barang',
              errorText: nameError,
            ),
            maxLength: shoppingItemNameMaxLength,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('shopping-item-quantity'),
            controller: _quantity,
            enabled: !state.busy,
            decoration: InputDecoration(
              labelText: 'Jumlah',
              errorText: quantityError,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(shoppingItemQuantityMaxDigits),
            ],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!state.busy) _submit();
            },
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
