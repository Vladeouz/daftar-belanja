import 'package:flutter/material.dart';

import 'package:app/features/notes/domain/entities/note.dart';

/// Satu baris di daftar note: judul, cuplikan isi, dan tanggal terakhir diubah (waktu lokal).
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final updated = MaterialLocalizations.of(context)
        .formatMediumDate(note.updatedAt.toLocal());
    return ListTile(
      title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: note.body.isEmpty
          ? null
          : Text(note.body, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(updated),
      onTap: onTap,
    );
  }
}
