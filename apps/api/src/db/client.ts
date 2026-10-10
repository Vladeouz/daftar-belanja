import { fileURLToPath } from 'node:url';
import { drizzle, type NodePgDatabase } from 'drizzle-orm/node-postgres';
import { migrate } from 'drizzle-orm/node-postgres/migrator';
import pg from 'pg';
import * as schema from './schema/index.js';

export type Database = NodePgDatabase<typeof schema>;

export interface DbClient {
  db: Database;
  pool: pg.Pool;
  close(): Promise<void>;
}

// `apps/api/drizzle`, baik dari `src/db` (tsx) maupun `dist/db` (build produksi).
export const MIGRATIONS_FOLDER = fileURLToPath(new URL('../../drizzle', import.meta.url));

export function createDb(databaseUrl: string, options: { max?: number } = {}): DbClient {
  const pool = new pg.Pool({ connectionString: databaseUrl, max: options.max ?? 10 });
  const db = drizzle(pool, { schema });
  return { db, pool, close: () => pool.end() };
}

// Idempoten: migrasi yang sudah tercatat di `drizzle.__drizzle_migrations` dilewati.
export async function runMigrations(db: Database): Promise<void> {
  await migrate(db, { migrationsFolder: MIGRATIONS_FOLDER });
}
