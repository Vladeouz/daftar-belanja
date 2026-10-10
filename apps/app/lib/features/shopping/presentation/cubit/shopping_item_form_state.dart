import 'package:equatable/equatable.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';

/// State form tambah/ubah barang (`ShoppingItemFormCubit`).
///
/// Tanpa state memuat: API tidak punya `GET /v1/shopping-items/{id}`, jadi barang yang
/// diubah selalu dibawa dari daftar.
sealed class ShoppingItemFormState extends Equatable {
  const ShoppingItemFormState();

  @override
  List<Object?> get props => [];
}

enum ShoppingItemFormStatus { idle, saving, deleting }

/// Form tampil. [item] `null` = menambah barang baru.
final class ShoppingItemFormEditing extends ShoppingItemFormState {
  const ShoppingItemFormEditing({
    this.item,
    this.status = ShoppingItemFormStatus.idle,
    this.failure,
  });

  final ShoppingItem? item;
  final ShoppingItemFormStatus status;

  /// Kegagalan simpan atau hapus terakhir. Nama yang sudah ada = `FailureCode.conflict`;
  /// error validasi API ada di `failure.fieldErrors` (`name`, `quantity`).
  final Failure? failure;

  bool get isNew => item == null;
  bool get busy => status != ShoppingItemFormStatus.idle;

  @override
  List<Object?> get props => [item, status, failure];
}

/// Tersimpan. Halaman kembali ke daftar membawa barang ini.
final class ShoppingItemFormSaved extends ShoppingItemFormState {
  const ShoppingItemFormSaved(this.item);

  final ShoppingItem item;

  @override
  List<Object?> get props => [item];
}

/// Terhapus. Halaman kembali ke daftar membawa id ini.
final class ShoppingItemFormDeleted extends ShoppingItemFormState {
  const ShoppingItemFormDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
