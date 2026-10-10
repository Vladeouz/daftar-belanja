import type { ShoppingItemRepository } from '../domain/shopping-item.js';

// Hanya barang milik `userId` yang terhapus; tidak ada barang yang sudah dibeli → `deletedCount` 0.
export function clearDoneShoppingItems({
  shoppingItems,
}: {
  shoppingItems: ShoppingItemRepository;
}) {
  return async (userId: string): Promise<{ deletedCount: number }> => ({
    deletedCount: await shoppingItems.deleteDone(userId),
  });
}

export type ClearDoneShoppingItems = ReturnType<typeof clearDoneShoppingItems>;
