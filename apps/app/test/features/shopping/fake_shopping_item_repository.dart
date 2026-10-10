import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_page.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';
import 'package:app/features/shopping/domain/repositories/shopping_item_repository.dart';

/// [ShoppingItemRepository] dalam memori yang meniru API shopping: terbaru lebih dulu,
/// filter status, pagination cursor (bawaan 20 per halaman), `NOT_FOUND` untuk id tak
/// dikenal, `CONFLICT` untuk nama yang sudah ada (tanpa membedakan huruf besar dan kecil),
/// dan `VALIDATION_ERROR` untuk nama kosong, jumlah di luar 1–999, atau ubah tanpa field.
class FakeShoppingItemRepository implements ShoppingItemRepository {
  /// [initialCount] barang `Barang 1`..`Barang n` (jumlah = nomornya); nomor di [doneNumbers]
  /// sudah dibeli.
  FakeShoppingItemRepository({
    int initialCount = 0,
    Set<int> doneNumbers = const {},
  }) {
    for (var i = 1; i <= initialCount; i++) {
      _insert(name: 'Barang $i', quantity: i, isDone: doneNumbers.contains(i));
    }
  }

  /// Tersimpan, terlama lebih dulu.
  final List<ShoppingItem> _items = [];
  var _clock = DateTime.utc(2026, 10);
  var _nextId = 1;

  /// `true` = setiap operasi gagal seperti API tidak bisa dihubungi.
  bool offline = false;

  /// Terbaru lebih dulu, seperti urutan API.
  List<ShoppingItem> get items => _items.reversed.toList();

  ShoppingItem byName(String name) => _items.singleWhere((i) => i.name == name);

  @override
  Future<Result<ShoppingItemPage>> list({
    ShoppingItemStatus? status,
    String? cursor,
    int? limit,
  }) async {
    if (offline) return _networkDown();
    final filtered = items
        .where(
          (i) => switch (status ?? ShoppingItemStatus.all) {
            ShoppingItemStatus.all => true,
            ShoppingItemStatus.open => !i.isDone,
            ShoppingItemStatus.done => i.isDone,
          },
        )
        .toList();
    // Cursor berbasis posisi seperti API: barang setelah barang [cursor] dalam urutan
    // terbaru lebih dulu, walaupun barang itu sudah dihapus.
    final start = cursor == null
        ? 0
        : filtered.indexWhere((i) => _order(i) < int.parse(cursor));
    final from = start == -1 ? filtered.length : start;
    final size = limit ?? 20;
    final page = filtered.skip(from).take(size).toList();
    final hasMore = from + page.length < filtered.length;
    return Ok(
      ShoppingItemPage(
        items: page,
        nextCursor: hasMore ? '${_order(page.last)}' : null,
      ),
    );
  }

  @override
  Future<Result<ShoppingItem>> create({
    required String name,
    int? quantity,
  }) async {
    if (offline) return _networkDown();
    final invalid = _validate(name: name, quantity: quantity);
    if (invalid != null) return Err(invalid);
    if (_nameTaken(name)) return _conflict();
    return Ok(_insert(name: name.trim(), quantity: quantity ?? 1));
  }

  @override
  Future<Result<ShoppingItem>> update(
    String id, {
    String? name,
    int? quantity,
    bool? isDone,
  }) async {
    if (offline) return _networkDown();
    if (name == null && quantity == null && isDone == null) {
      return const Err(
        Failure(
          FailureCode.validation,
          fieldErrors: {
            '_root': [FieldIssue('custom', 'At least one field is required')],
          },
        ),
      );
    }
    final invalid = _validate(name: name, quantity: quantity);
    if (invalid != null) return Err(invalid);
    final index = _indexOf(id);
    if (index == -1) return _notFound();
    if (name != null && _nameTaken(name, except: id)) return _conflict();
    final old = _items[index];
    final updated = ShoppingItem(
      id: old.id,
      name: name?.trim() ?? old.name,
      quantity: quantity ?? old.quantity,
      isDone: isDone ?? old.isDone,
      createdAt: old.createdAt,
      updatedAt: _tick(),
    );
    _items[index] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (offline) return _networkDown();
    final index = _indexOf(id);
    if (index == -1) return _notFound();
    _items.removeAt(index);
    return const Ok(null);
  }

  @override
  Future<Result<int>> clearDone() async {
    if (offline) return _networkDown();
    final before = _items.length;
    _items.removeWhere((i) => i.isDone);
    return Ok(before - _items.length);
  }

  ShoppingItem _insert({
    required String name,
    required int quantity,
    bool isDone = false,
  }) {
    final now = _tick();
    final item = ShoppingItem(
      id: 'item-${_nextId++}',
      name: name,
      quantity: quantity,
      isDone: isDone,
      createdAt: now,
      updatedAt: now,
    );
    _items.add(item);
    return item;
  }

  DateTime _tick() => _clock = _clock.add(const Duration(minutes: 1));

  int _indexOf(String id) => _items.indexWhere((i) => i.id == id);

  /// Posisi urutan (makin besar makin baru), dipakai sebagai cursor.
  static int _order(ShoppingItem item) => item.createdAt.millisecondsSinceEpoch;

  bool _nameTaken(String name, {String? except}) => _items.any(
    (i) => i.id != except && i.name.toLowerCase() == name.trim().toLowerCase(),
  );

  static Failure? _validate({String? name, int? quantity}) {
    final fieldErrors = <String, List<FieldIssue>>{
      if (name != null && name.trim().isEmpty)
        'name': const [FieldIssue('too_small', 'Too small')],
      if (name != null && name.trim().length > 80)
        'name': const [FieldIssue('too_big', 'Too big')],
      if (quantity != null && quantity < 1)
        'quantity': const [FieldIssue('too_small', 'Too small')],
      if (quantity != null && quantity > 999)
        'quantity': const [FieldIssue('too_big', 'Too big')],
    };
    return fieldErrors.isEmpty
        ? null
        : Failure(FailureCode.validation, fieldErrors: fieldErrors);
  }

  static Err<T> _networkDown<T>() => Err(const Failure(FailureCode.network));

  static Err<T> _notFound<T>() => Err(
    const Failure(FailureCode.notFound, message: 'Shopping item not found'),
  );

  static Err<T> _conflict<T>() => Err(
    const Failure(
      FailureCode.conflict,
      message: 'Shopping item name already exists',
    ),
  );
}
