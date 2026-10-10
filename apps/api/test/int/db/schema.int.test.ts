import { randomUUID } from 'node:crypto';
import { eq } from 'drizzle-orm';
import pg from 'pg';
import { describe, expect, inject, it } from 'vitest';
import { runMigrations } from '../../../src/db/client.js';
import { users } from '../../../src/db/schema/index.js';
import { useTestDb } from '../../helpers/db.js';
import { testDatabaseUrls } from '../../setup/db.js';

// Kode SQLSTATE PostgreSQL.
const UNIQUE_VIOLATION = '23505';
const CHECK_VIOLATION = '23514';

const getDb = useTestDb();

const query = async <T extends pg.QueryResultRow = Record<string, unknown>>(
  text: string,
  values: unknown[] = [],
) => (await getDb().pool.query<T>(text, values)).rows;

async function expectPgError(promise: Promise<unknown>, code: string, constraint: string) {
  const error = await promise.then(
    () => undefined,
    (e: unknown) => e as { code?: string; constraint?: string },
  );
  expect(error, 'query seharusnya gagal').toBeDefined();
  expect(error?.code).toBe(code);
  expect(error?.constraint).toBe(constraint);
}

describe('migrasi', () => {
  it('membuat tabel users dengan kolom dan tipe sesuai bagian 4 PRD', async () => {
    const rows = await query<{
      column_name: string;
      data_type: string;
      is_nullable: string;
      column_default: string | null;
    }>(
      `select column_name, data_type, is_nullable, column_default from information_schema.columns
       where table_schema = 'public' and table_name = 'users' order by ordinal_position`,
    );
    const columns = Object.fromEntries(rows.map((r) => [r.column_name, r]));

    expect(Object.keys(columns).sort()).toEqual(
      [
        'created_at',
        'display_name',
        'email',
        'firebase_uid',
        'id',
        'last_seen_at',
        'updated_at',
      ].sort(),
    );
    expect(columns.id).toMatchObject({ data_type: 'uuid', is_nullable: 'NO' });
    expect(columns.id?.column_default).toBe('gen_random_uuid()');
    expect(columns.firebase_uid).toMatchObject({ data_type: 'text', is_nullable: 'NO' });
    expect(columns.email).toMatchObject({ data_type: 'text', is_nullable: 'YES' });
    expect(columns.display_name).toMatchObject({ data_type: 'text', is_nullable: 'YES' });
    for (const name of ['last_seen_at', 'created_at', 'updated_at']) {
      expect(columns[name], name).toMatchObject({
        data_type: 'timestamp with time zone',
        is_nullable: 'NO',
        column_default: 'now()',
      });
    }
  });

  it('semua kolom timestamp di schema public berpresisi milidetik (timestamptz(3))', async () => {
    const rows = await query<{ column: string; data_type: string; precision: number }>(
      `select table_name || '.' || column_name as column, data_type,
              datetime_precision as precision
         from information_schema.columns
        where table_schema = 'public' and data_type like 'timestamp%'
        order by 1`,
    );

    expect(rows.map((r) => r.column)).toEqual(
      expect.arrayContaining(['notes.created_at', 'users.last_seen_at', 'users.updated_at']),
    );
    for (const row of rows) {
      expect(row, row.column).toMatchObject({
        data_type: 'timestamp with time zone',
        precision: 3,
      });
    }
  });

  it('nilai di bawah milidetik dibulatkan ke milidetik', async () => {
    const [row] = await query<{ created_at: Date; micros: string }>(
      `insert into users (firebase_uid, created_at) values ('uid-1', '2026-10-01T08:00:00.123456Z')
       returning created_at, to_char(created_at at time zone 'UTC', 'US') as micros`,
    );

    expect(row?.micros).toBe('123000');
    expect(row?.created_at.toISOString()).toBe('2026-10-01T08:00:00.123Z');
  });

  it('idempoten: menjalankan migrasi lagi tidak mengubah apa pun', async () => {
    const count = async () =>
      (await query<{ n: number }>(`select count(*)::int as n from drizzle.__drizzle_migrations`))[0]
        ?.n;
    const before = await count();
    expect(before).toBeGreaterThan(0);

    await runMigrations(getDb().db);

    expect(await count()).toBe(before);
  });
});

describe('users', () => {
  it('firebase_uid unik', async () => {
    await query(`insert into users (firebase_uid) values ('uid-1')`);
    await expectPgError(
      query(`insert into users (firebase_uid) values ('uid-1')`),
      UNIQUE_VIOLATION,
      'users_firebase_uid_unique',
    );
  });

  it('upsert ON CONFLICT (firebase_uid) memperbarui baris yang sama', async () => {
    const upsert = (email: string) =>
      getDb()
        .db.insert(users)
        .values({ firebaseUid: 'uid-1', email })
        .onConflictDoUpdate({ target: users.firebaseUid, set: { email } })
        .returning();

    const [first] = await upsert('a@mail.com');
    const [second] = await upsert('b@mail.com');

    expect(second?.id).toBe(first?.id);
    expect(second?.email).toBe('b@mail.com');
    expect(await query(`select id from users`)).toHaveLength(1);
  });

  it('email harus lowercase, boleh null', async () => {
    await expectPgError(
      query(`insert into users (firebase_uid, email) values ('uid-1', 'Budi@Mail.com')`),
      CHECK_VIOLATION,
      'users_email_lowercase_check',
    );
    await query(`insert into users (firebase_uid, email) values ('uid-2', null)`);
  });

  it('mengisi id, created_at, dan updated_at; updated_at diperbarui lewat Drizzle', async () => {
    const { db } = getDb();
    // `updated_at` awal di masa lalu: presisi milidetik membuat insert dan update bisa jatuh di
    // milidetik yang sama.
    const [created] = await db
      .insert(users)
      .values({ firebaseUid: 'uid-1', updatedAt: new Date(Date.now() - 60_000) })
      .returning();
    expect(created?.id).toMatch(/^[0-9a-f-]{36}$/);
    expect(created?.createdAt).toBeInstanceOf(Date);

    const [updated] = await db
      .update(users)
      .set({ displayName: 'Budi' })
      .where(eq(users.firebaseUid, 'uid-1'))
      .returning();

    expect(updated?.updatedAt.getTime()).toBeGreaterThan(created?.updatedAt.getTime() ?? 0);
    expect(updated?.createdAt).toEqual(created?.createdAt);
  });
});

describe('database test', () => {
  it('memakai database <nama>_test, bukan database utama', async () => {
    const { mainDbName, testDbName } = testDatabaseUrls(inject('mainDatabaseUrl'));
    const [row] = await query<{ name: string }>(`select current_database() as name`);

    expect(row?.name).toBe(testDbName);
    expect(row?.name).not.toBe(mainDbName);
  });

  it('tabel di-TRUNCATE sebelum setiap test', async () => {
    // Test sebelumnya di file ini menyisipkan baris users.
    expect(await query(`select id from users`)).toHaveLength(0);
  });

  it('data yang ditulis test tidak muncul di database utama', async () => {
    const uid = `int-test-${randomUUID()}`;
    await query(`insert into users (firebase_uid) values ($1)`, [uid]);

    const main = new pg.Client({ connectionString: inject('mainDatabaseUrl') });
    await main.connect();
    try {
      const [table] = (
        await main.query<{ users: string | null }>(`select to_regclass('public.users') as users`)
      ).rows;
      // Database utama yang belum dimigrasi tidak punya tabel users sama sekali.
      if (table?.users) {
        const { rows } = await main.query(`select id from users where firebase_uid = $1`, [uid]);
        expect(rows).toHaveLength(0);
      }
    } finally {
      await main.end();
    }
  });
});
