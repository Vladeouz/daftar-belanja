// Menjalankan migrasi di `apps/api/drizzle/` ke DATABASE_URL.
// Dipakai lewat `pnpm --filter api db:migrate` dan oleh container produksi (`node dist/db/migrate.js`).
import { EnvError, loadDatabaseUrl } from '../core/config/env.js';
import { createDb, runMigrations } from './client.js';

let databaseUrl: string;
try {
  databaseUrl = loadDatabaseUrl();
} catch (err) {
  if (err instanceof EnvError) {
    console.error(err.message);
    process.exit(1);
  }
  throw err;
}

const client = createDb(databaseUrl, { max: 1 });
try {
  await runMigrations(client.db);
  console.log('Migrations applied');
} finally {
  await client.close();
}
