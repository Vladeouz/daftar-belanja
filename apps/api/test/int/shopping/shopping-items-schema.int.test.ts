import { randomUUID } from 'node:crypto';
import { eq } from 'drizzle-orm';
import { describe, expect, it } from 'vitest';
import { shoppingItems, users } from '../../../src/db/schema/index.js';
import { useTestDb } from '../../helpers/db.js';
import { insertShoppingItem, insertUser } from '../../helpers/factories.js';

// Constraint tabel `shopping_items` (PRD bagian 4) ditegakkan database, terlepas dari validasi
// route.

// Kode SQLSTATE PostgreSQL.
const UNIQUE_VIOLATION = '23505';
const CHECK_VIOLATION = '23514';
const FOREIGN_KEY_VIOLATION = '23503';

const getDb = useTestDb();

async function expectPgError(promise: Promise<unknown>, code: string, constraint: string) {
  const error = await promise.then(
    () => undefined,
    (e: unknown) => (e as { cause?: unknown }).cause ?? e,
  );
  expect(error, 'query seharusnya gagal').toBeDefined();
  expect(error).toMatchObject({ code, constraint });
}

const insertRaw = (userId: string, name: string, quantity?: number) =>
  quantity === undefined
    ? getDb().pool.query(`insert into shopping_items (user_id, name) values ($1, $2)`, [
        userId,
        name,
      ])
    : getDb().pool.query(
        `insert into shopping_items (user_id, name, quantity) values ($1, $2, $3)`,
        [userId, name, quantity],
      );

describe('shopping_items', () => {
  it('quantity default 1 dan is_done default false', async () => {
    const user = await insertUser(getDb().db);

    const { rows } = await getDb().pool.query<{ quantity: number; is_done: boolean }>(
      `insert into shopping_items (user_id, name) values ($1, 'Telur') returning quantity, is_done`,
      [user.id],
    );

    expect(rows[0]).toEqual({ quantity: 1, is_done: false });
  });

  it('name harus 1–80 karakter (shopping_items_name_length_check)', async () => {
    const user = await insertUser(getDb().db);

    await expectPgError(
      insertRaw(user.id, ''),
      CHECK_VIOLATION,
      'shopping_items_name_length_check',
    );
    await expectPgError(
      insertRaw(user.id, 'x'.repeat(81)),
      CHECK_VIOLATION,
      'shopping_items_name_length_check',
    );
    await insertRaw(user.id, 'x');
    await insertRaw(user.id, 'é'.repeat(80));
  });

  it('quantity harus 1–999 (shopping_items_quantity_range_check)', async () => {
    const user = await insertUser(getDb().db);

    for (const quantity of [0, 1000]) {
      await expectPgError(
        insertRaw(user.id, `Barang ${quantity}`, quantity),
        CHECK_VIOLATION,
        'shopping_items_quantity_range_check',
      );
    }
    await insertRaw(user.id, 'Satu', 1);
    await insertRaw(user.id, 'Banyak', 999);
  });

  it('nama unik per user tanpa membedakan huruf besar dan kecil (shopping_items_user_id_name_unique)', async () => {
    const { db } = getDb();
    const a = await insertUser(db);
    const b = await insertUser(db);
    await insertRaw(a.id, 'Telur');

    await expectPgError(
      insertRaw(a.id, 'TELUR'),
      UNIQUE_VIOLATION,
      'shopping_items_user_id_name_unique',
    );
    await insertRaw(b.id, 'telur');
  });

  it('user_id harus merujuk users (shopping_items_user_id_fk)', async () => {
    await expectPgError(
      insertRaw(randomUUID(), 'Yatim'),
      FOREIGN_KEY_VIOLATION,
      'shopping_items_user_id_fk',
    );
  });

  it('barang ikut terhapus saat user dihapus (ON DELETE CASCADE)', async () => {
    const { db } = getDb();
    const owner = await insertUser(db);
    const other = await insertUser(db);
    await insertShoppingItem(db, { userId: owner.id });
    await insertShoppingItem(db, { userId: other.id });

    await db.delete(users).where(eq(users.id, owner.id));

    const left = await db.select().from(shoppingItems);
    expect(left.map((i) => i.userId)).toEqual([other.id]);
  });

  it('index (user_id, created_at DESC, id DESC) melayani urutan pagination tanpa Sort', async () => {
    const { rows } = await getDb().pool.query<{ indexdef: string }>(
      `select indexdef from pg_indexes where tablename = 'shopping_items'
         and indexname = 'shopping_items_user_id_created_at_id_index'`,
    );
    expect(rows[0]?.indexdef).toMatch(/\(user_id, created_at DESC, id DESC\)$/);

    // Tabel kecil di test; seq scan dimatikan agar planner memilih index bila bisa dipakai.
    const client = await getDb().pool.connect();
    try {
      await client.query('set enable_seqscan = off');
      const plan = await client.query<{ 'QUERY PLAN': string }>(
        `explain select * from shopping_items where user_id = $1 and is_done = false
           and (created_at, id) < (now(), $1::uuid)
           order by created_at desc, id desc limit 11`,
        [randomUUID()],
      );
      const text = plan.rows.map((r) => r['QUERY PLAN']).join('\n');
      expect(text).toContain('shopping_items_user_id_created_at_id_index');
      expect(text).not.toMatch(/\bSort\b/);
    } finally {
      await client.query('reset enable_seqscan');
      client.release();
    }
  });
});
