import { describe, expect, it } from 'vitest';
import { updateShoppingItem } from '../../../../../src/features/shopping/usecases/update-shopping-item.js';
import { fakeShoppingItemRepository } from '../fake-shopping-item-repository.js';

const T1 = new Date('2026-10-01T08:00:00.000Z');
const T2 = new Date('2026-10-01T09:00:00.000Z');

async function seed() {
  let at = T1;
  const fake = fakeShoppingItemRepository({ now: () => at });
  const item = await fake.repo.create({ userId: 'user-a', name: 'Telur', quantity: 2 });
  const other = await fake.repo.create({ userId: 'user-a', name: 'Beras', quantity: 1 });
  at = T2;
  return { ...fake, item, other };
}

describe('updateShoppingItem', () => {
  it('changes only isDone when only isDone is sent', async () => {
    const { repo, item } = await seed();

    const updated = await updateShoppingItem({ shoppingItems: repo })('user-a', item.id, {
      isDone: true,
    });

    expect(updated).toEqual({ ...item, isDone: true, updatedAt: T2 });
  });

  it('changes name and quantity', async () => {
    const { repo, item } = await seed();

    const updated = await updateShoppingItem({ shoppingItems: repo })('user-a', item.id, {
      name: 'Telur ayam',
      quantity: 10,
    });

    expect(updated).toMatchObject({ name: 'Telur ayam', quantity: 10, isDone: false });
  });

  it('allows changing the case of its own name', async () => {
    const { repo, item } = await seed();

    const updated = await updateShoppingItem({ shoppingItems: repo })('user-a', item.id, {
      name: 'TELUR',
    });

    expect(updated.name).toBe('TELUR');
  });

  it('throws CONFLICT when renaming to the name of another item and leaves it unchanged', async () => {
    const { repo, rows, item } = await seed();

    await expect(
      updateShoppingItem({ shoppingItems: repo })('user-a', item.id, { name: 'beras' }),
    ).rejects.toMatchObject({ code: 'CONFLICT', status: 409 });
    expect(rows.get(item.id)).toEqual(item);
  });

  it('throws NOT_FOUND for an item of another user and leaves it unchanged', async () => {
    const { repo, rows, item } = await seed();

    await expect(
      updateShoppingItem({ shoppingItems: repo })('user-b', item.id, { isDone: true }),
    ).rejects.toMatchObject({ code: 'NOT_FOUND', status: 404 });
    expect(rows.get(item.id)).toEqual(item);
  });

  it('rethrows other repository errors as is', async () => {
    const { repo, item } = await seed();
    const boom = new Error('connection lost');
    repo.update = async () => {
      throw boom;
    };

    await expect(
      updateShoppingItem({ shoppingItems: repo })('user-a', item.id, { isDone: true }),
    ).rejects.toBe(boom);
  });
});
