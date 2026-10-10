// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shopping_item.g.dart';

@JsonSerializable()
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ShoppingItem.fromJson(Map<String, Object?> json) => _$ShoppingItemFromJson(json);
  
  final String id;
  final String name;
  final int quantity;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$ShoppingItemToJson(this);
}
