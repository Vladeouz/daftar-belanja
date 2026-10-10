import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_cubit.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_state.dart';
import 'package:app/features/shopping/presentation/widgets/shopping_item_form.dart';

/// Halaman tambah atau ubah barang. Butuh [ShoppingItemFormCubit] dari `BlocProvider`
/// (dipasang router).
///
/// Setelah tersimpan atau terhapus, halaman ditutup dengan `context.pop(state)` sehingga
/// halaman daftar menerima `ShoppingItemFormSaved`/`ShoppingItemFormDeleted`.
class ShoppingItemFormPage extends StatelessWidget {
  const ShoppingItemFormPage({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<ShoppingItemFormCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus barang?'),
        content: const Text('Barang yang dihapus tidak bisa dikembalikan.'),
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
    return BlocConsumer<ShoppingItemFormCubit, ShoppingItemFormState>(
      listenWhen: (_, state) =>
          state is ShoppingItemFormSaved || state is ShoppingItemFormDeleted,
      listener: (context, state) => context.pop(state),
      // Form tetap tampil selama halaman ditutup.
      buildWhen: (_, state) => state is ShoppingItemFormEditing,
      builder: (context, state) {
        // Hanya `ShoppingItemFormEditing` yang dibangun (lihat `buildWhen`; state awal
        // Cubit juga Editing).
        final editing = state as ShoppingItemFormEditing;
        return Scaffold(
          appBar: AppBar(
            title: Text(editing.isNew ? 'Tambah barang' : 'Ubah barang'),
            actions: [
              if (!editing.isNew)
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
          body: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ShoppingItemForm(
                  // Field diisi ulang bila barang yang dibuka berganti.
                  key: ValueKey(editing.item?.id),
                  state: editing,
                  onSave: (name, quantity) => context
                      .read<ShoppingItemFormCubit>()
                      .save(name: name, quantity: quantity),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
