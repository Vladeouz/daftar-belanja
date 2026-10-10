import { defineConfig } from 'drizzle-kit';

// `pnpm --filter api db:generate` membuat migrasi SQL baru di `drizzle/` dari skema;
// migrasi di-commit dan dijalankan dengan `db:migrate`.
export default defineConfig({
  dialect: 'postgresql',
  schema: './src/db/schema/index.ts',
  out: './drizzle',
  // Hanya dipakai perintah yang terhubung ke database (studio). `generate` dan `check` tidak.
  dbCredentials: { url: process.env.DATABASE_URL ?? '' },
  strict: true,
  verbose: true,
});
