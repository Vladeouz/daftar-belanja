// Global setup integration test: membuat ulang database `<POSTGRES_DB>_test` dari DATABASE_URL
// dan menjalankan migrasi yang di-commit. Data di database utama tidak pernah disentuh;
// koneksi ke database utama hanya dipakai untuk DROP/CREATE database test.
import pg from 'pg';
import type { TestProject } from 'vitest/node';
import { loadDatabaseUrl } from '../../src/core/config/env.js';
import { createDb, runMigrations } from '../../src/db/client.js';
// Global setup berjalan di proses utama Vitest, bukan di worker, jadi default env dipasang di sini juga.
import './env.js';

declare module 'vitest' {
  export interface ProvidedContext {
    databaseUrl: string;
    mainDatabaseUrl: string;
  }
}

export function testDatabaseUrls(databaseUrl: string) {
  const url = new URL(databaseUrl);
  const mainDbName = decodeURIComponent(url.pathname.slice(1));
  const testDbName = `${mainDbName}_test`;
  url.pathname = `/${testDbName}`;
  return { mainUrl: databaseUrl, mainDbName, testUrl: url.toString(), testDbName };
}

export default async function setup(project: TestProject) {
  const { mainUrl, testUrl, testDbName } = testDatabaseUrls(loadDatabaseUrl());

  const admin = new pg.Client({ connectionString: mainUrl });
  try {
    await admin.connect();
  } catch (err) {
    throw new Error(
      `Tidak bisa terhubung ke PostgreSQL (${new URL(mainUrl).host}). ` +
        'Pastikan Docker Desktop berjalan, lalu `docker compose up -d --wait`.',
      { cause: err },
    );
  }
  try {
    const name = pg.escapeIdentifier(testDbName);
    await admin.query(`DROP DATABASE IF EXISTS ${name} WITH (FORCE)`);
    await admin.query(`CREATE DATABASE ${name}`);
  } finally {
    await admin.end();
  }

  const client = createDb(testUrl, { max: 1 });
  try {
    await runMigrations(client.db);
  } finally {
    await client.close();
  }

  project.provide('databaseUrl', testUrl);
  project.provide('mainDatabaseUrl', mainUrl);
}
