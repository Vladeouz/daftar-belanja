import { randomUUID } from 'node:crypto';
import type { Database } from '../../src/db/client.js';
import { shoppingItems, users } from '../../src/db/schema/index.js';

// Membuat baris langsung di database test untuk menyiapkan data integration test. Data yang
// diuji lewat HTTP tetap dibuat lewat route; factory hanya untuk keadaan awal.

export type UserRow = typeof users.$inferSelect;

export async function insertUser(
  db: Database,
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<UserRow> {
  const [row] = await db
    .insert(users)
    .values({ firebaseUid: `uid-${randomUUID()}`, ...overrides })
    .returning();
  if (!row) throw new Error('insertUser: tidak ada baris');
  return row;
}

export type ShoppingItemRow = typeof shoppingItems.$inferSelect;

export async function insertShoppingItem(
  db: Database,
  values: Pick<typeof shoppingItems.$inferInsert, 'userId'> &
    Partial<typeof shoppingItems.$inferInsert>,
): Promise<ShoppingItemRow> {
  const [row] = await db
    .insert(shoppingItems)
    .values({ name: `Barang ${randomUUID()}`, ...values })
    .returning();
  if (!row) throw new Error('insertShoppingItem: tidak ada baris');
  return row;
}

// `count` barang bernama `Barang 1`…`Barang n` dengan `created_at` berbeda 1 detik (barang ke-1
// paling lama). `isDone(i)` menentukan status barang ke-i (mulai 1).
export async function insertShoppingItems(
  db: Database,
  userId: string,
  count: number,
  isDone: (i: number) => boolean = () => false,
  start = new Date('2026-10-01T08:00:00.000Z'),
): Promise<ShoppingItemRow[]> {
  const rows: ShoppingItemRow[] = [];
  for (let i = 1; i <= count; i++) {
    rows.push(
      await insertShoppingItem(db, {
        userId,
        name: `Barang ${i}`,
        isDone: isDone(i),
        createdAt: new Date(start.getTime() + (i - 1) * 1000),
      }),
    );
  }
  return rows;
}
