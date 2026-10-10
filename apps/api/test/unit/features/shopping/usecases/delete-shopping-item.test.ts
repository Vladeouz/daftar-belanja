import { describe, expect, it } from 'vitest';
import { deleteShoppingItem } from '../../../../../src/features/shopping/usecases/delete-shopping-item.js';
import { fakeShoppingItemRepository } from '../fake-shopping-item-repository.js';

describe('deleteShoppingItem', () => {
  it('deletes the item of its owner', async () => {
    const { repo, rows } = fakeShoppingItemRepository();
    const item = await repo.create({ userId: 'user-a', name: 'Telur', quantity: 1 });

    await deleteShoppingItem({ shoppingItems: repo })('user-a', item.id);

    expect(rows.has(item.id)).toBe(false);
  });

  it('throws NOT_FOUND for an item of another user and keeps it', async () => {
    const { repo, rows } = fakeShoppingItemRepository();
    const item = await repo.create({ userId: 'user-a', name: 'Telur', quantity: 1 });

    await expect(
      deleteShoppingItem({ shoppingItems: repo })('user-b', item.id),
    ).rejects.toMatchObject({ code: 'NOT_FOUND', status: 404 });
    expect(rows.has(item.id)).toBe(true);
  });

  it('throws NOT_FOUND when deleting twice', async () => {
    const { repo } = fakeShoppingItemRepository();
    const item = await repo.create({ userId: 'user-a', name: 'Telur', quantity: 1 });
    const remove = deleteShoppingItem({ shoppingItems: repo });

    await remove('user-a', item.id);

    await expect(remove('user-a', item.id)).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });
});
