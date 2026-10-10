import 'package:flutter/material.dart';

import 'package:app/features/shopping/domain/entities/shopping_item.dart';

/// Satu baris di daftar belanja: checkbox sudah dibeli, nama (dicoret bila sudah dibeli),
/// dan jumlah. Ketuk baris untuk mengubah barang.
class ShoppingItemTile extends StatelessWidget {
  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.updating,
    required this.onToggle,
    required this.onTap,
  });

  final ShoppingItem item;

  /// Status barang sedang disimpan; checkbox nonaktif.
  final bool updating;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Checkbox(
        value: item.isDone,
        semanticLabel: item.isDone
            ? 'Tandai ${item.name} belum dibeli'
            : 'Tandai ${item.name} sudah dibeli',
        onChanged: updating ? null : (_) => onToggle(),
      ),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: item.isDone
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
      ),
      trailing: Text('× ${item.quantity}'),
      onTap: onTap,
    );
  }
}
