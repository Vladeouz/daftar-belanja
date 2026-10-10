// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'clear_done_shopping_items_result.g.dart';

@JsonSerializable()
class ClearDoneShoppingItemsResult {
  const ClearDoneShoppingItemsResult({
    required this.deletedCount,
  });
  
  factory ClearDoneShoppingItemsResult.fromJson(Map<String, Object?> json) => _$ClearDoneShoppingItemsResultFromJson(json);
  
  final int deletedCount;

  Map<String, Object?> toJson() => _$ClearDoneShoppingItemsResultToJson(this);
}
