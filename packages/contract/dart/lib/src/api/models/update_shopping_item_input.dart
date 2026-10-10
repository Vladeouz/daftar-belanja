// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_shopping_item_input.g.dart';

@JsonSerializable()
class UpdateShoppingItemInput {
  const UpdateShoppingItemInput({
    this.name,
    this.quantity,
    this.isDone,
  });
  
  factory UpdateShoppingItemInput.fromJson(Map<String, Object?> json) => _$UpdateShoppingItemInputFromJson(json);
  
  @JsonKey(includeIfNull: false)
  final String? name;
  @JsonKey(includeIfNull: false)
  final int? quantity;
  @JsonKey(includeIfNull: false)
  final bool? isDone;

  Map<String, Object?> toJson() => _$UpdateShoppingItemInputToJson(this);
}
