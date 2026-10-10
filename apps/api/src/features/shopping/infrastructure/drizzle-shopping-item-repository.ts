import { and, desc, eq, sql } from 'drizzle-orm';
import { buildPage } from '../../../core/http/pagination.js';
import type { Database } from '../../../db/client.js';
import { shoppingItems } from '../../../db/schema/index.js';
import {
  type ShoppingItem,
  ShoppingItemNameTakenError,
  type ShoppingItemRepository,
  type ShoppingItemStatus,
} from '../domain/shopping-item.js';

type ShoppingItemRow = typeof shoppingItems.$inferSelect;

const UNIQUE_VIOLATION = '23505';
const NAME_UNIQUE = 'shopping_items_user_id_name_unique';

function toShoppingItem(row: ShoppingItemRow): ShoppingItem {
  return {
    id: row.id,
    userId: row.userId,
    name: row.name,
    quantity: row.quantity,
    isDone: row.isDone,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

// Drizzle membungkus error `pg` di `cause`. Pelanggaran keunikan nama menjadi error domain;
// error lain dilempar ulang apa adanya.
async function mapNameTaken<T>(query: PromiseLike<T>): Promise<T> {
  try {
    return await query;
  } catch (error) {
    const pgError = ((error as { cause?: unknown }).cause ?? error) as {
      code?: string;
      constraint?: string;
    };
    if (pgError.code === UNIQUE_VIOLATION && pgError.constraint === NAME_UNIQUE) {
      throw new ShoppingItemNameTakenError();
    }
    throw error;
  }
}

function statusFilter(status: ShoppingItemStatus) {
  if (status === 'open') return eq(shoppingItems.isDone, false);
  if (status === 'done') return eq(shoppingItems.isDone, true);
  return undefined;
}

export function createDrizzleShoppingItemRepository(db: Database): ShoppingItemRepository {
  const owned = (userId: string, id: string) =>
    and(eq(shoppingItems.id, id), eq(shoppingItems.userId, userId));

  return {
    async create(input) {
      const [row] = await mapNameTaken(db.insert(shoppingItems).values(input).returning());
      if (!row) throw new Error('insert shopping_items tidak mengembalikan baris');
      return toShoppingItem(row);
    },

    async listByUser(userId, { limit, cursor, status }) {
      // Ambil `limit + 1` baris; baris tambahan hanya menandakan ada halaman berikutnya.
      const rows = await db
        .select()
        .from(shoppingItems)
        .where(
          and(
            eq(shoppingItems.userId, userId),
            statusFilter(status),
            cursor
              ? sql`(${shoppingItems.createdAt}, ${shoppingItems.id}) < (${cursor.createdAt}::timestamptz, ${cursor.id}::uuid)`
              : undefined,
          ),
        )
        .orderBy(desc(shoppingItems.createdAt), desc(shoppingItems.id))
        .limit(limit + 1);

      return buildPage(rows.map(toShoppingItem), limit, (item) => item);
    },

    async update(userId, id, changes) {
      // `updated_at` diisi `$onUpdate` Drizzle.
      const [row] = await mapNameTaken(
        db
          .update(shoppingItems)
          .set({ name: changes.name, quantity: changes.quantity, isDone: changes.isDone })
          .where(owned(userId, id))
          .returning(),
      );
      return row ? toShoppingItem(row) : null;
    },

    async delete(userId, id) {
      const rows = await db
        .delete(shoppingItems)
        .where(owned(userId, id))
        .returning({ id: shoppingItems.id });
      return rows.length > 0;
    },

    async deleteDone(userId) {
      const rows = await db
        .delete(shoppingItems)
        .where(and(eq(shoppingItems.userId, userId), eq(shoppingItems.isDone, true)))
        .returning({ id: shoppingItems.id });
      return rows.length;
    },
  };
}
