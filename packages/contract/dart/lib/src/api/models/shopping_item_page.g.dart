// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingItemPage _$ShoppingItemPageFromJson(Map<String, dynamic> json) =>
    ShoppingItemPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$ShoppingItemPageToJson(ShoppingItemPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
