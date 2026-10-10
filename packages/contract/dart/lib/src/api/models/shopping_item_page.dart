// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shopping_item.dart';

part 'shopping_item_page.g.dart';

@JsonSerializable()
class ShoppingItemPage {
  const ShoppingItemPage({
    required this.items,
    required this.nextCursor,
  });
  
  factory ShoppingItemPage.fromJson(Map<String, Object?> json) => _$ShoppingItemPageFromJson(json);
  
  final List<ShoppingItem> items;

  /// `null` di halaman terakhir
  @JsonKey(includeIfNull: true)
  final String? nextCursor;

  Map<String, Object?> toJson() => _$ShoppingItemPageToJson(this);
}
