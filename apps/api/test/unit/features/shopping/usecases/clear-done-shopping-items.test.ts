import { describe, expect, it } from 'vitest';
import { clearDoneShoppingItems } from '../../../../../src/features/shopping/usecases/clear-done-shopping-items.js';
import { fakeShoppingItemRepository } from '../fake-shopping-item-repository.js';

async function seed(repo: ReturnType<typeof fakeShoppingItemRepository>['repo']) {
  const create = async (userId: string, name: string, isDone: boolean) => {
    const item = await repo.create({ userId, name, quantity: 1 });
    if (isDone) await repo.update(userId, item.id, { isDone: true });
    return item.id;
  };
  return {
    doneA: [await create('user-a', 'Telur', true), await create('user-a', 'Susu', true)],
    openA: [await create('user-a', 'Beras', false)],
    doneB: [await create('user-b', 'Kopi', true)],
  };
}

describe('clearDoneShoppingItems', () => {
  it('deletes only the done items of the owner and returns the count', async () => {
    const { repo, rows } = fakeShoppingItemRepository();
    const { doneA, openA, doneB } = await seed(repo);

    const result = await clearDoneShoppingItems({ shoppingItems: repo })('user-a');

    expect(result).toEqual({ deletedCount: 2 });
    expect([...rows.keys()].sort()).toEqual([...openA, ...doneB].sort());
    for (const id of doneA) expect(rows.has(id)).toBe(false);
  });

  it('returns 0 when the owner has no done items', async () => {
    const { repo, rows } = fakeShoppingItemRepository();
    await seed(repo);

    const clear = clearDoneShoppingItems({ shoppingItems: repo });
    await clear('user-a');

    expect(await clear('user-a')).toEqual({ deletedCount: 0 });
    expect(await clear('user-c')).toEqual({ deletedCount: 0 });
    expect(rows.size).toBe(2);
  });
});
