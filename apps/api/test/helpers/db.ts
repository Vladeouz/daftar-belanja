import { afterAll, beforeAll, beforeEach, inject } from 'vitest';
import { createDb, type DbClient } from '../../src/db/client.js';

// Dipanggil sekali di level atas file integration test:
//   const getDb = useTestDb();
// Membuka pool ke database test, men-TRUNCATE semua tabel `public` sebelum setiap test,
// dan menutup pool setelah file selesai.
export function useTestDb(): () => DbClient {
  let client: DbClient | undefined;

  beforeAll(() => {
    client = createDb(inject('databaseUrl'), { max: 4 });
  });

  beforeEach(async () => {
    await truncateAll(getClient());
  });

  afterAll(async () => {
    await client?.close();
  });

  function getClient(): DbClient {
    if (!client) throw new Error('useTestDb(): database dipakai sebelum beforeAll');
    return client;
  }

  return getClient;
}

// Semua tabel di schema `public` (tabel baru otomatis ikut). Riwayat migrasi Drizzle
// ada di schema `drizzle` dan tabel pg-boss di schema `pgboss`, jadi tidak ikut terhapus.
export async function truncateAll(client: DbClient): Promise<void> {
  const { rows } = await client.pool.query<{ name: string }>(
    `select format('%I', tablename) as name from pg_tables where schemaname = 'public'`,
  );
  if (rows.length === 0) return;
  await client.pool.query(
    `truncate ${rows.map((r) => r.name).join(', ')} restart identity cascade`,
  );
}
