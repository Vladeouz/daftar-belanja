import { AppError } from '../../../core/http/errors.js';
import {
  type ShoppingItem,
  ShoppingItemNameTakenError,
  type ShoppingItemRepository,
} from '../domain/shopping-item.js';

export interface CreateShoppingItemInput {
  userId: string;
  name: string;
  quantity?: number;
}

// Nama yang sudah ada (tanpa membedakan huruf besar dan kecil) → `CONFLICT` (D-01).
export function createShoppingItem({ shoppingItems }: { shoppingItems: ShoppingItemRepository }) {
  return async (input: CreateShoppingItemInput): Promise<ShoppingItem> => {
    try {
      return await shoppingItems.create({
        userId: input.userId,
        name: input.name,
        quantity: input.quantity ?? 1,
      });
    } catch (error) {
      if (error instanceof ShoppingItemNameTakenError) {
        throw new AppError('CONFLICT', error.message);
      }
      throw error;
    }
  };
}

export type CreateShoppingItem = ReturnType<typeof createShoppingItem>;
