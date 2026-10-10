import { describe, expect, it } from 'vitest';
import { AppError } from '../../../../../src/core/http/errors.js';
import { createShoppingItem } from '../../../../../src/features/shopping/usecases/create-shopping-item.js';
import { fakeShoppingItemRepository } from '../fake-shopping-item-repository.js';

const T1 = new Date('2026-10-01T08:00:00.000Z');

describe('createShoppingItem', () => {
  it('creates an item owned by the user with quantity 1 and isDone false by default', async () => {
    const { repo, rows } = fakeShoppingItemRepository({ now: () => T1 });

    const item = await createShoppingItem({ shoppingItems: repo })({
      userId: 'user-a',
      name: 'Telur',
    });

    expect(item).toMatchObject({
      userId: 'user-a',
      name: 'Telur',
      quantity: 1,
      isDone: false,
      createdAt: T1,
      updatedAt: T1,
    });
    expect(rows.get(item.id)).toEqual(item);
  });

  it('keeps the given quantity', async () => {
    const { repo } = fakeShoppingItemRepository();

    const item = await createShoppingItem({ shoppingItems: repo })({
      userId: 'user-a',
      name: 'Beras',
      quantity: 3,
    });

    expect(item.quantity).toBe(3);
  });

  it('throws CONFLICT when the name already exists in another case and adds nothing', async () => {
    const { repo, rows } = fakeShoppingItemRepository();
    const create = createShoppingItem({ shoppingItems: repo });
    await create({ userId: 'user-a', name: 'Telur' });

    const error = await create({ userId: 'user-a', name: 'telur' }).catch((e: unknown) => e);

    expect(error).toBeInstanceOf(AppError);
    expect(error).toMatchObject({ code: 'CONFLICT', status: 409 });
    expect(rows.size).toBe(1);
  });

  it('allows the same name for different users', async () => {
    const { repo } = fakeShoppingItemRepository();
    const create = createShoppingItem({ shoppingItems: repo });
    await create({ userId: 'user-a', name: 'Telur' });

    await expect(create({ userId: 'user-b', name: 'Telur' })).resolves.toMatchObject({
      userId: 'user-b',
    });
  });

  it('rethrows other repository errors as is', async () => {
    const { repo } = fakeShoppingItemRepository();
    const boom = new Error('connection lost');
    repo.create = async () => {
      throw boom;
    };

    await expect(
      createShoppingItem({ shoppingItems: repo })({ userId: 'user-a', name: 'Telur' }),
    ).rejects.toBe(boom);
  });
});
