import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/failure_messages.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_state.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_list_cubit.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_list_state.dart';
import 'package:app/features/shopping/presentation/widgets/failure_view.dart';
import 'package:app/features/shopping/presentation/widgets/load_more_footer.dart';
import 'package:app/features/shopping/presentation/widgets/shopping_item_tile.dart';

/// Daftar belanja milik user (halaman utama). Butuh [ShoppingListCubit] dari `BlocProvider`
/// (dipasang router).
///
/// Filter Semua/Belum/Sudah di atas daftar; checkbox menandai sudah/belum dibeli; tombol
/// "Hapus yang sudah dibeli" di app bar selalu lewat dialog konfirmasi. Kegagalan kedua aksi
/// itu tampil sebagai SnackBar.
///
/// Form dibuka dengan `context.push`; hasilnya (`ShoppingItemFormSaved`/`Deleted`)
/// diterapkan ke daftar tanpa memuat ulang. Kembali tanpa hasil (tombol kembali, atau form
/// dibuka lewat URL sehingga hasilnya tidak sampai ke sini) memuat ulang halaman pertama.
class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  /// Rute halaman ini paling atas (tidak tertutup form).
  bool? _isCurrent;

  /// Form di atas halaman ini dibuka lewat [_openForm], yang menangani hasilnya sendiri.
  bool _openedHere = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    final returned = _isCurrent == false && isCurrent;
    _isCurrent = isCurrent;
    if (!returned) return;
    if (_openedHere) {
      _openedHere = false;
    } else {
      // Form dibuka lewat URL (`/shopping/new`): hasilnya tidak kembali ke daftar ini,
      // jadi ambil ulang dari API.
      context.read<ShoppingListCubit>().load();
    }
  }

  Future<void> _openForm({ShoppingItem? item}) async {
    final cubit = context.read<ShoppingListCubit>();
    final location = item == null
        ? AppRoutes.shoppingNew
        : AppRoutes.shoppingItem(item.id);
    _openedHere = true;
    final result = await context.push<ShoppingItemFormState>(
      location,
      extra: item,
    );
    switch (result) {
      case ShoppingItemFormSaved(:final item):
        cubit.itemSaved(item);
      case ShoppingItemFormDeleted(:final id):
        cubit.itemDeleted(id);
      case _:
        cubit.load();
    }
  }

  Future<void> _confirmClearDone() async {
    final cubit = context.read<ShoppingListCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus yang sudah dibeli?'),
        content: const Text(
          'Semua barang yang sudah dibeli akan dihapus dari daftar dan tidak '
          'bisa dikembalikan.',
        ),
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
    if (confirmed ?? false) await cubit.clearDone();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShoppingListCubit, ShoppingListState>(
      listenWhen: (previous, current) =>
          current is ShoppingListLoaded &&
          current.actionFailure != null &&
          (previous is! ShoppingListLoaded ||
              previous.actionFailure != current.actionFailure),
      listener: (context, state) {
        final failure = (state as ShoppingListLoaded).actionFailure!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failureMessage(failure.code))));
      },
      builder: (context, state) {
        final canClear = state is ShoppingListLoaded && !state.clearing;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daftar belanja'),
            actions: [
              IconButton(
                tooltip: 'Hapus yang sudah dibeli',
                icon: const Icon(Icons.remove_done),
                onPressed: canClear ? _confirmClearDone : null,
              ),
              const SignOutButton(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Tambah barang',
            onPressed: () => _openForm(),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _StatusFilter(
                  selected: state.filter,
                  onChanged: (filter) =>
                      context.read<ShoppingListCubit>().setFilter(filter),
                ),
              ),
              if (state is ShoppingListLoaded && state.clearing)
                const LinearProgressIndicator(),
              Expanded(child: _body(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, ShoppingListState state) =>
      switch (state) {
        ShoppingListLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        ShoppingListLoadFailed(:final failure) => FailureView(
          failure: failure,
          onRetry: () => context.read<ShoppingListCubit>().load(),
        ),
        ShoppingListLoaded(items: [], hasMore: false) => Center(
          child: Text(_emptyMessage(state.filter)),
        ),
        final ShoppingListLoaded loaded => ListView.builder(
          // Ruang di bawah agar baris terakhir tidak tertutup tombol tambah.
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: loaded.items.length + (loaded.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == loaded.items.length) {
              return LoadMoreFooter(
                state: loaded,
                onLoadMore: () => context.read<ShoppingListCubit>().loadMore(),
              );
            }
            final item = loaded.items[index];
            return ShoppingItemTile(
              key: ValueKey(item.id),
              item: item,
              updating: loaded.updatingIds.contains(item.id),
              onToggle: () =>
                  context.read<ShoppingListCubit>().toggleDone(item),
              onTap: () => _openForm(item: item),
            );
          },
        ),
      };

  static String _emptyMessage(ShoppingItemStatus filter) => switch (filter) {
    ShoppingItemStatus.all => 'Daftar belanja masih kosong.',
    ShoppingItemStatus.open => 'Tidak ada barang yang belum dibeli.',
    ShoppingItemStatus.done => 'Belum ada barang yang sudah dibeli.',
  };
}

/// Pilihan filter Semua / Belum / Sudah.
class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.selected, required this.onChanged});

  final ShoppingItemStatus selected;
  final ValueChanged<ShoppingItemStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ShoppingItemStatus>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: ShoppingItemStatus.all, label: Text('Semua')),
        ButtonSegment(value: ShoppingItemStatus.open, label: Text('Belum')),
        ButtonSegment(value: ShoppingItemStatus.done, label: Text('Sudah')),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
