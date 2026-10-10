/// Filter status daftar belanja (query `status` di `GET /v1/shopping-items`).
enum ShoppingItemStatus {
  /// Semua barang (bawaan API).
  all,

  /// Belum dibeli.
  open,

  /// Sudah dibeli.
  done,
}
