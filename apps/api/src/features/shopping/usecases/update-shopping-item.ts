import { AppError } from '../../../core/http/errors.js';
import {
  type ShoppingItem,
  type ShoppingItemChanges,
  ShoppingItemNameTakenError,
  type ShoppingItemRepository,
} from '../domain/shopping-item.js';

// Hanya field yang dikirim yang diubah. Barang milik user lain → `NOT_FOUND` (D-07); nama baru
// yang sudah dipakai barang lain → `CONFLICT` (D-01).
export function updateShoppingItem({ shoppingItems }: { shoppingItems: ShoppingItemRepository }) {
  return async (
    userId: string,
    id: string,
    changes: ShoppingItemChanges,
  ): Promise<ShoppingItem> => {
    let item: ShoppingItem | null;
    try {
      item = await shoppingItems.update(userId, id, changes);
    } catch (error) {
      if (error instanceof ShoppingItemNameTakenError) {
        throw new AppError('CONFLICT', error.message);
      }
      throw error;
    }
    if (!item) throw new AppError('NOT_FOUND', 'Shopping item not found');
    return item;
  };
}

export type UpdateShoppingItem = ReturnType<typeof updateShoppingItem>;
