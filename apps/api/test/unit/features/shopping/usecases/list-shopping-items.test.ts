import { describe, expect, it } from 'vitest';
import { decodeCursor } from '../../../../../src/core/http/pagination.js';
import { listShoppingItems } from '../../../../../src/features/shopping/usecases/list-shopping-items.js';
import { fakeShoppingItemRepository } from '../fake-shopping-item-repository.js';

// Barang ke-i dibuat pada detik ke-i, jadi barang terbaru adalah yang terakhir dibuat. Barang
// bernomor genap sudah dibeli.
async function seed(count: number, userId = 'user-a') {
  let second = 0;
  const fake = fakeShoppingItemRepository({
    now: () => new Date(Date.UTC(2026, 9, 1, 8, 0, second++)),
  });
  for (let i = 1; i <= count; i++) {
    const item = await fake.repo.create({ userId, name: `Barang ${i}`, quantity: 1 });
    if (i % 2 === 0) await fake.repo.update(userId, item.id, { isDone: true });
  }
  return fake;
}

describe('listShoppingItems', () => {
  it('returns the newest items first with a cursor to the next page', async () => {
    const { repo } = await seed(5);

    const page = await listShoppingItems({ shoppingItems: repo })('user-a', {
      limit: 2,
      status: 'all',
    });

    expect(page.items.map((i) => i.name)).toEqual(['Barang 5', 'Barang 4']);
    expect(decodeCursor(page.nextCursor ?? '')?.id).toBe(page.items[1]?.id);
  });

  it('continues after the cursor and ends with nextCursor null', async () => {
    const { repo } = await seed(3);
    const list = listShoppingItems({ shoppingItems: repo });

    const first = await list('user-a', { limit: 2, status: 'all' });
    const cursor = decodeCursor(first.nextCursor ?? '') ?? undefined;
    const second = await list('user-a', { limit: 2, cursor, status: 'all' });

    expect(second.items.map((i) => i.name)).toEqual(['Barang 1']);
    expect(second.nextCursor).toBeNull();
  });

  it.each([
    ['open', ['Barang 5', 'Barang 3', 'Barang 1']],
    ['done', ['Barang 4', 'Barang 2']],
  ] as const)('filters by status %s', async (status, names) => {
    const { repo } = await seed(5);

    const page = await listShoppingItems({ shoppingItems: repo })('user-a', {
      limit: 20,
      status,
    });

    expect(page.items.map((i) => i.name)).toEqual(names);
    expect(page.nextCursor).toBeNull();
  });

  it('only lists items of the given user', async () => {
    const { repo } = await seed(2);
    await repo.create({ userId: 'user-b', name: 'Punya B', quantity: 1 });

    const page = await listShoppingItems({ shoppingItems: repo })('user-b', {
      limit: 20,
      status: 'all',
    });

    expect(page.items.map((i) => i.name)).toEqual(['Punya B']);
  });
});
