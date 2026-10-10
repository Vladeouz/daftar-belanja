// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_shopping_item_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateShoppingItemInput _$UpdateShoppingItemInputFromJson(
  Map<String, dynamic> json,
) => UpdateShoppingItemInput(
  name: json['name'] as String?,
  quantity: (json['quantity'] as num?)?.toInt(),
  isDone: json['isDone'] as bool?,
);

Map<String, dynamic> _$UpdateShoppingItemInputToJson(
  UpdateShoppingItemInput instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'quantity': ?instance.quantity,
  'isDone': ?instance.isDone,
};
