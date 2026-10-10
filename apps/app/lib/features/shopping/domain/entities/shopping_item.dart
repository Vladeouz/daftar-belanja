import 'package:equatable/equatable.dart';

/// Barang di daftar belanja milik user yang login.
class ShoppingItem extends Equatable {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
  });

  /// UUID dari API.
  final String id;

  /// 1–80 karakter, sudah dirapikan API; unik per user tanpa membedakan huruf besar dan kecil.
  final String name;

  /// 1–999.
  final int quantity;

  /// `true` bila sudah dibeli.
  final bool isDone;

  /// UTC.
  final DateTime createdAt;

  /// UTC.
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, name, quantity, isDone, createdAt, updatedAt];
}
