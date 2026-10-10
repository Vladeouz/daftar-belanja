import 'package:api_client/api_client.dart' as dto;

import 'package:app/features/shopping/domain/entities/shopping_item.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_page.dart';
import 'package:app/features/shopping/domain/entities/shopping_item_status.dart';

/// DTO `ShoppingItem` → entity. Timestamp sudah UTC (API mengirim ISO 8601 berakhiran `Z`).
ShoppingItem shoppingItemFromDto(dto.ShoppingItem item) => ShoppingItem(
  id: item.id,
  name: item.name,
  quantity: item.quantity,
  isDone: item.isDone,
  createdAt: item.createdAt,
  updatedAt: item.updatedAt,
);

ShoppingItemPage shoppingItemPageFromDto(dto.ShoppingItemPage page) =>
    ShoppingItemPage(
      items: List.unmodifiable(page.items.map(shoppingItemFromDto)),
      nextCursor: page.nextCursor,
    );

/// Filter status entity → nilai query `status` di kontrak.
dto.ShoppingItemStatus shoppingItemStatusToDto(ShoppingItemStatus status) =>
    switch (status) {
      ShoppingItemStatus.all => dto.ShoppingItemStatus.all,
      ShoppingItemStatus.open => dto.ShoppingItemStatus.open,
      ShoppingItemStatus.done => dto.ShoppingItemStatus.done,
    };
