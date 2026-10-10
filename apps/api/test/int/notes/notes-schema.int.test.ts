import { randomUUID } from 'node:crypto';
import { eq } from 'drizzle-orm';
import { describe, expect, it } from 'vitest';
import { notes, users } from '../../../src/db/schema/index.js';
import { useTestDb } from '../../helpers/db.js';
import { insertNote, insertUser } from '../../helpers/factories.js';

// Constraint tabel `notes` (PRD bagian 4) ditegakkan database, terlepas dari validasi route.

// Kode SQLSTATE PostgreSQL.
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

const insertRaw = (userId: string, title: string, body = '') =>
  getDb().pool.query(`insert into notes (user_id, title, body) values ($1, $2, $3)`, [
    userId,
    title,
    body,
  ]);

describe('notes', () => {
  it('title harus 1–120 karakter (notes_title_length_check)', async () => {
    const user = await insertUser(getDb().db);

    await expectPgError(insertRaw(user.id, ''), CHECK_VIOLATION, 'notes_title_length_check');
    await expectPgError(
      insertRaw(user.id, 'x'.repeat(121)),
      CHECK_VIOLATION,
      'notes_title_length_check',
    );
    await insertRaw(user.id, 'x');
    await insertRaw(user.id, 'x'.repeat(120));
  });

  it('panjang title dihitung per karakter, bukan per byte', async () => {
    const user = await insertUser(getDb().db);

    await insertRaw(user.id, 'é'.repeat(120));
  });

  it('body maksimal 5000 karakter (notes_body_length_check), default kosong', async () => {
    const user = await insertUser(getDb().db);

    await expectPgError(
      insertRaw(user.id, 'Judul', 'y'.repeat(5001)),
      CHECK_VIOLATION,
      'notes_body_length_check',
    );
    await insertRaw(user.id, 'Judul', 'y'.repeat(5000));
    const { rows } = await getDb().pool.query<{ body: string }>(
      `insert into notes (user_id, title) values ($1, 'Tanpa body') returning body`,
      [user.id],
    );
    expect(rows[0]?.body).toBe('');
  });

  it('CHECK juga berlaku untuk update lewat Drizzle', async () => {
    const { db } = getDb();
    const user = await insertUser(db);
    const note = await insertNote(db, { userId: user.id });

    await expectPgError(
      db.update(notes).set({ title: '' }).where(eq(notes.id, note.id)),
      CHECK_VIOLATION,
      'notes_title_length_check',
    );
  });

  it('user_id harus merujuk users (notes_user_id_fk)', async () => {
    await expectPgError(
      insertRaw(randomUUID(), 'Yatim'),
      FOREIGN_KEY_VIOLATION,
      'notes_user_id_fk',
    );
  });

  it('note ikut terhapus saat user dihapus (ON DELETE CASCADE)', async () => {
    const { db } = getDb();
    const owner = await insertUser(db);
    const other = await insertUser(db);
    await insertNote(db, { userId: owner.id });
    await insertNote(db, { userId: other.id });

    await db.delete(users).where(eq(users.id, owner.id));

    const left = await db.select().from(notes);
    expect(left.map((n) => n.userId)).toEqual([other.id]);
  });

  it('updated_at diperbarui lewat Drizzle, created_at tetap', async () => {
    const { db } = getDb();
    const user = await insertUser(db);
    const note = await insertNote(db, { userId: user.id });

    const [updated] = await db
      .update(notes)
      .set({ title: 'Baru' })
      .where(eq(notes.id, note.id))
      .returning();

    expect(updated?.updatedAt.getTime()).toBeGreaterThanOrEqual(note.updatedAt.getTime());
    expect(updated?.createdAt).toEqual(note.createdAt);
  });

  it('index (user_id, created_at DESC, id DESC) melayani urutan pagination tanpa Sort', async () => {
    const { rows } = await getDb().pool.query<{ indexdef: string }>(
      `select indexdef from pg_indexes where tablename = 'notes'
         and indexname = 'notes_user_id_created_at_id_index'`,
    );
    expect(rows[0]?.indexdef).toMatch(/\(user_id, created_at DESC, id DESC\)$/);

    // Tabel kecil di test; seq scan dimatikan agar planner memilih index bila bisa dipakai.
    const client = await getDb().pool.connect();
    try {
      await client.query('set enable_seqscan = off');
      const plan = await client.query<{ 'QUERY PLAN': string }>(
        `explain select * from notes where user_id = $1
           and (created_at, id) < (now(), $1::uuid)
           order by created_at desc, id desc limit 11`,
        [randomUUID()],
      );
      const text = plan.rows.map((r) => r['QUERY PLAN']).join('\n');
      expect(text).toContain('notes_user_id_created_at_id_index');
      expect(text).not.toMatch(/\bSort\b/);
    } finally {
      await client.query('reset enable_seqscan');
      client.release();
    }
  });
});
