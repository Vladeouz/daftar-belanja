// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_shopping_item_input.dart';
import '../models/shopping_item.dart';
import '../models/shopping_item_page.dart';
import '../models/shopping_item_status.dart';
import '../models/update_shopping_item_input.dart';

part 'shopping_client.g.dart';

@RestApi()
abstract class ShoppingClient {
  factory ShoppingClient(Dio dio, {String? baseUrl}) = _ShoppingClient;

  /// Daftar barang belanja milik user, terbaru lebih dulu.
  ///
  /// [cursor] - Nilai `nextCursor` dari halaman sebelumnya.
  ///
  /// [status] - `open` belum dibeli, `done` sudah dibeli.
  @GET('/v1/shopping-items')
  Future<ShoppingItemPage> listShoppingItems({
    @Query('cursor') String? cursor,
    @Query('status') ShoppingItemStatus? status,
    @Query('limit') int? limit = 20,
  });

  /// Tambah barang belanja
  @POST('/v1/shopping-items')
  Future<ShoppingItem> createShoppingItem({
    @Body() required CreateShoppingItemInput body,
  });

  /// Ubah nama, jumlah, dan/atau status barang
  @PATCH('/v1/shopping-items/{id}')
  Future<ShoppingItem> updateShoppingItem({
    @Path('id') required String id,
    @Body() required UpdateShoppingItemInput body,
  });

  /// Hapus barang
  @DELETE('/v1/shopping-items/{id}')
  Future<void> deleteShoppingItem({
    @Path('id') required String id,
  });
}
