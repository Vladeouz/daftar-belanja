import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/create_shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/delete_shopping_item.dart';
import 'package:app/features/shopping/domain/usecases/update_shopping_item.dart';
import 'package:app/features/shopping/presentation/cubit/shopping_item_form_state.dart';

/// Form tambah/ubah/hapus barang. State awal: form barang baru; router memanggil [edit]
/// dengan barang yang dibawa dari daftar.
class ShoppingItemFormCubit extends Cubit<ShoppingItemFormState> {
  ShoppingItemFormCubit({
    required this._createItem,
    required this._updateItem,
    required this._deleteItem,
  }) : super(const ShoppingItemFormEditing());

  final CreateShoppingItem _createItem;
  final UpdateShoppingItem _updateItem;
  final DeleteShoppingItem _deleteItem;

  void edit(ShoppingItem item) => emit(ShoppingItemFormEditing(item: item));

  /// Menambah barang baru atau mengubah nama dan jumlah barang yang dibuka. [quantity]
  /// `null` = tidak dikirim (barang baru: API menyimpan 1; ubah: jumlah tidak berubah).
  /// Diabaikan saat masih menyimpan atau menghapus. Nama yang sudah ada dan error validasi
  /// API kembali ke form lewat `failure`.
  Future<void> save({required String name, int? quantity}) async {
    final current = state;
    if (current is! ShoppingItemFormEditing || current.busy) return;
    final item = current.item;
    emit(
      ShoppingItemFormEditing(
        item: item,
        status: ShoppingItemFormStatus.saving,
      ),
    );
    final result = item == null
        ? await _createItem(name: name, quantity: quantity)
        : await _updateItem(item.id, name: name, quantity: quantity);
    if (isClosed) return;
    emit(switch (result) {
      Ok(value: final saved) => ShoppingItemFormSaved(saved),
      Err(:final failure) => ShoppingItemFormEditing(
        item: item,
        failure: failure,
      ),
    });
  }

  /// Menghapus barang yang dibuka. Diabaikan untuk barang baru atau saat masih sibuk.
  Future<void> delete() async {
    final current = state;
    if (current is! ShoppingItemFormEditing || current.busy) return;
    final item = current.item;
    if (item == null) return;
    emit(
      ShoppingItemFormEditing(
        item: item,
        status: ShoppingItemFormStatus.deleting,
      ),
    );
    final result = await _deleteItem(item.id);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => ShoppingItemFormDeleted(item.id),
      Err(:final failure) => ShoppingItemFormEditing(
        item: item,
        failure: failure,
      ),
    });
  }
}
