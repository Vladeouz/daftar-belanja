// Menulis dokumen OpenAPI 3.1 dari route app ke `packages/contract/openapi.json` (D-01), atau ke
// path di argumen pertama (dipakai `contract:check` untuk menulis ke folder sementara).
// Dipanggil lewat `pnpm contract:generate` (scripts/contract.mjs), bukan langsung.
import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createApp } from '../src/app.js';
import { createLogger } from '../src/core/logger.js';
import { createNoneFileStorage, createNonePushSender } from '../src/core/ports/adapters/none.js';
import { createDb } from '../src/db/client.js';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const outFile = resolve(process.argv[2] ?? resolve(repoRoot, 'packages/contract/openapi.json'));

// Dokumen hanya bergantung pada route yang terdaftar. Pool database tidak membuka koneksi sampai
// ada query, jadi export tidak butuh `.env`, Docker, atau Auth Emulator.
const { db, close } = createDb('postgres://localhost/unused', { max: 1 });
const app = createApp({
  logger: createLogger({ level: 'silent' }),
  corsOrigins: [],
  db,
  tokenVerifier: { verify: async () => null },
  ports: { pushSender: createNonePushSender(), fileStorage: createNoneFileStorage() },
});
const document = app.getOpenAPI31Document({
  openapi: '3.1.0',
  info: { title: 'API', version: '1' },
});
await close();

// `JSON.stringify` memecah array pendek per baris, Biome tidak. Format dengan Biome dari root
// (lewat stdin, agar file di luar repo juga memakai `biome.json`) supaya `pnpm lint` bersih dan
// hasilnya sama dengan yang di-commit.
const biome = spawnSync('pnpm exec biome format --stdin-file-path=packages/contract/openapi.json', {
  cwd: repoRoot,
  shell: true,
  input: `${JSON.stringify(document, null, 2)}\n`,
  encoding: 'utf8',
});
if (biome.status !== 0) {
  process.stderr.write(biome.stderr);
  throw new Error('biome format gagal untuk openapi.json');
}

mkdirSync(dirname(outFile), { recursive: true });
writeFileSync(outFile, biome.stdout);
console.log(`openapi.json ditulis: ${outFile}`);
