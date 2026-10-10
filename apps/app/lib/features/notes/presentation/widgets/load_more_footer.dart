import 'package:flutter/material.dart';

import 'package:app/core/l10n/failure_messages.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_state.dart';

/// Baris terakhir daftar selama masih ada halaman berikutnya.
///
/// `ListView.builder` baru membangun baris ini saat digulir mendekati bawah, jadi
/// [onLoadMore] dipanggil tepat saat itu (juga bila halaman pertama tidak memenuhi layar).
/// Bila gagal, tampil pesan dan tombol "Coba lagi"; tidak dicoba ulang otomatis.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.state,
    required this.onLoadMore,
  });

  final NotesListLoaded state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final failure = state.loadMoreFailure;
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(failureMessage(failure.code), textAlign: TextAlign.center),
            TextButton(onPressed: onLoadMore, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    const spinner = Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
    return state.loadingMore
        ? spinner
        : _OnFirstBuild(callback: onLoadMore, child: spinner);
  }
}

/// Memanggil [callback] sekali setelah frame pertama widget ini dibangun.
class _OnFirstBuild extends StatefulWidget {
  const _OnFirstBuild({required this.callback, required this.child});

  final VoidCallback callback;
  final Widget child;

  @override
  State<_OnFirstBuild> createState() => _OnFirstBuildState();
}

class _OnFirstBuildState extends State<_OnFirstBuild> {
  @override
  void initState() {
    super.initState();
    // Tidak memanggil Cubit di tengah build: emit saat build membuat BlocBuilder error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.callback();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
