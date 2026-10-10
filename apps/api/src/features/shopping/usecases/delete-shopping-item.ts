import { AppError } from '../../../core/http/errors.js';
import type { ShoppingItemRepository } from '../domain/shopping-item.js';

// Barang milik user lain → `NOT_FOUND` (D-07).
export function deleteShoppingItem({ shoppingItems }: { shoppingItems: ShoppingItemRepository }) {
  return async (userId: string, id: string): Promise<void> => {
    const deleted = await shoppingItems.delete(userId, id);
    if (!deleted) throw new AppError('NOT_FOUND', 'Shopping item not found');
  };
}

export type DeleteShoppingItem = ReturnType<typeof deleteShoppingItem>;
