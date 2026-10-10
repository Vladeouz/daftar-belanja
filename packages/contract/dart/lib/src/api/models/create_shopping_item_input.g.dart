// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_shopping_item_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateShoppingItemInput _$CreateShoppingItemInputFromJson(
  Map<String, dynamic> json,
) => CreateShoppingItemInput(
  name: json['name'] as String,
  quantity: (json['quantity'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateShoppingItemInputToJson(
  CreateShoppingItemInput instance,
) => <String, dynamic>{'name': instance.name, 'quantity': ?instance.quantity};
