import type { Page } from '../../../core/http/pagination.js';
import type {
  ListShoppingItemsQuery,
  ShoppingItem,
  ShoppingItemRepository,
} from '../domain/shopping-item.js';

export function listShoppingItems({ shoppingItems }: { shoppingItems: ShoppingItemRepository }) {
  return (userId: string, query: ListShoppingItemsQuery): Promise<Page<ShoppingItem>> =>
    shoppingItems.listByUser(userId, query);
}

export type ListShoppingItems = ReturnType<typeof listShoppingItems>;
