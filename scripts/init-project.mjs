// Memulai proyek baru dari template (FR-16). Dijalankan sekali, di salinan repo template:
//
//   node scripts/init-project.mjs <nama>   (pnpm init-project <nama>)
//
// <nama> huruf kecil, angka, dan tanda hubung, misalnya `gym-membership`. Script mengganti:
//   - project Firebase `demo-template` → `demo-<nama>` (prefix `demo-` tetap: emulator saja),
//   - nama database `template` → `<nama>` dengan `-` menjadi `_` (database test `<nama>_test`),
//   - judul README dan `name` di package.json root,
//   - `docs/PRD.md` dan `docs/TASKS.md` dengan placeholder, serta mengosongkan `docs/logs/`.
// Yang diganti hanya file yang dilacak Git, kecuali `docs/template-build/` (sejarah template) dan
// script ini. `.env` tidak disentuh. Penanda sudah dijalankan: `docs/PRD.md` ada atau
// `.firebaserc` tidak lagi berisi `demo-template`; script menolak jalan untuk kedua kalinya.
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const TEMPLATE_PROJECT_ID = 'demo-template';
const TEMPLATE_DATABASE = 'template';
const EXCLUDED = [/^docs\/template-build\//, /^scripts\/init-project\.mjs$/, /^pnpm-lock\.yaml$/];
// Project ID Firebase maksimal 30 karakter, jadi `<nama>` maksimal 30 - `demo-`.
const MAX_NAME_LENGTH = 30 - 'demo-'.length;

class InitError extends Error {}

function validateName(name) {
  if (!name) throw new InitError('Pemakaian: pnpm init-project <nama>   (contoh: gym-membership)');
  if (!/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/.test(name)) {
    throw new InitError(
      `Nama "${name}" tidak valid: pakai huruf kecil, angka, dan tanda hubung, diawali huruf ` +
        '(contoh: gym-membership).',
    );
  }
  if (name.length > MAX_NAME_LENGTH) {
    throw new InitError(
      `Nama "${name}" terlalu panjang (${name.length} karakter, maksimal ${MAX_NAME_LENGTH}): ` +
        `project Firebase demo-${name} melebihi 30 karakter.`,
    );
  }
  if (name === TEMPLATE_DATABASE) throw new InitError('Nama "template" dipakai template sendiri.');
}

function assertNotInitialized() {
  const firebaserc = readFileSync(join(ROOT, '.firebaserc'), 'utf8');
  if (existsSync(join(ROOT, 'docs', 'PRD.md')) || !firebaserc.includes(TEMPLATE_PROJECT_ID)) {
    throw new InitError(
      'Proyek ini sudah diinisialisasi (docs/PRD.md sudah ada atau .firebaserc tidak lagi berisi ' +
        `${TEMPLATE_PROJECT_ID}). init-project hanya dijalankan sekali, pada salinan baru template.`,
    );
  }
}

function trackedFiles() {
  const result = spawnSync('git ls-files -z', { cwd: ROOT, shell: true, encoding: 'utf8' });
  if (result.status !== 0) {
    throw new InitError(`git ls-files gagal; jalankan dari salinan repo Git.\n${result.stderr}`);
  }
  return result.stdout
    .split('\0')
    .filter((file) => file && !EXCLUDED.some((pattern) => pattern.test(file)));
}

function replacementsFor(name) {
  const projectId = `demo-${name}`;
  const database = name.replaceAll('-', '_');
  return [
    [/demo-template/g, projectId],
    // Database utama: `POSTGRES_DB=template`, `POSTGRES_DB: template`, `${POSTGRES_DB:-template}`,
    // `...:5432/template`, dan `pg_isready ... -d template` (ci.yml). User dan password tetap.
    [/(POSTGRES_DB[=:] ?|POSTGRES_DB:-|:5432\/|-d )template\b/g, `$1${database}`],
    [/\btemplate_test\b/g, `${database}_test`],
  ];
}

// Mengganti isi file teks yang dilacak Git; file biner (berisi byte 0) dilewati.
function replaceInFiles(files, replacements) {
  const changed = [];
  for (const file of files) {
    const path = join(ROOT, file);
    if (!existsSync(path)) continue;
    const buffer = readFileSync(path);
    if (buffer.includes(0)) continue;
    const original = buffer.toString('utf8');
    let content = original;
    for (const [pattern, value] of replacements) content = content.replace(pattern, value);
    if (content !== original) {
      writeFileSync(path, content);
      changed.push(file);
    }
  }
  return changed;
}

function updateFile(file, edit) {
  const path = join(ROOT, file);
  const original = readFileSync(path, 'utf8');
  const content = edit(original);
  if (content === original) throw new InitError(`Pola yang diharapkan tidak ditemukan di ${file}.`);
  writeFileSync(path, content);
}

function prdPlaceholder(name) {
  return `# PRD — ${name}

> Placeholder dari \`pnpm init-project\`. Isi setiap bagian sebelum task pertama dikerjakan.
> Contoh PRD lengkap: \`docs/template-build/PRD.md\`. Konvensi teknis sudah ada di
> \`docs/conventions.md\`; tulis di sini hanya yang khusus proyek ini.

## 1. Context & Goal

Masalah yang diselesaikan, siapa penggunanya, dan tujuan yang terukur.

## 2. Scope

### In scope

- …

### Non-goals

- …

## 3. Tech Constraints

Tambahan atau penyimpangan dari \`docs/conventions.md\` (library baru, layanan eksternal, platform).

## 4. Data Model

Tabel baru beserta relasinya (diagram mermaid \`erDiagram\`).

## 5. API Contract

Endpoint baru (\`method path\` → respons, kode error). Format error dan autentikasi mengikuti
\`docs/conventions.md\`.

## 6. Functional Requirements

### FR-01: …

Acceptance criteria:
- [ ] Given …, When …, Then …

## 7. Non-Functional Requirements

- **NFR-01 …:** …

## 8. Assumptions & Decisions

| ID | Keputusan | Alasan |
| --- | --- | --- |
| D-01 | … | … |

### Open Questions

- …
`;
}

function tasksPlaceholder(name) {
  return `# TASKS — ${name}

> Placeholder dari \`pnpm init-project\`. Tulis task setelah \`docs/PRD.md\` terisi. Contoh daftar
> task lengkap: \`docs/template-build/TASKS.md\`.

Setiap task dikerjakan dalam satu sesi. Kriteria bertanda **(manual)** diverifikasi user: agent menjelaskan langkahnya, lalu menunggu konfirmasi sebelum mencentang.

Format setiap task:

\`\`\`md
- [ ] T-001 Judul task
  - layer: api | app | infra | docs · depends_on: - · refs: FR-01, D-01
  - files: \`path/file.ts\`, \`path/lain.dart\`
  - done when: kriteria yang bisa dibuktikan dengan perintah; \`pnpm check\` hijau
\`\`\`

## Fase 1 — …
`;
}

function main() {
  const name = process.argv[2];
  validateName(name);
  assertNotInitialized();

  const changed = replaceInFiles(trackedFiles(), replacementsFor(name));

  updateFile('README.md', (content) =>
    content
      .replace(/^# Template Starter Profil A$/m, `# ${name}`)
      .replace(
        /^Template untuk proyek Profil A: /m,
        'Proyek Profil A, dibuat dari Template Starter Profil A: ',
      ),
  );
  updateFile('package.json', (content) =>
    content.replace(/"name": "profil-a-template"/, `"name": "${name}"`),
  );

  const docs = join(ROOT, 'docs');
  writeFileSync(join(docs, 'PRD.md'), prdPlaceholder(name));
  writeFileSync(join(docs, 'TASKS.md'), tasksPlaceholder(name));
  const logs = join(docs, 'logs');
  rmSync(logs, { recursive: true, force: true });
  mkdirSync(logs);
  writeFileSync(join(logs, '.gitkeep'), '');

  // Sisa nama lama berarti ada pola yang belum ditangani script ini.
  const leftover = trackedFiles().filter((file) => {
    const path = join(ROOT, file);
    return existsSync(path) && readFileSync(path, 'utf8').includes(TEMPLATE_PROJECT_ID);
  });
  if (leftover.length > 0) {
    throw new InitError(`Masih ada ${TEMPLATE_PROJECT_ID} di: ${leftover.join(', ')}`);
  }

  const database = name.replaceAll('-', '_');
  console.log(`Proyek ${name} diinisialisasi.`);
  console.log(`  project Firebase : demo-${name}`);
  console.log(`  database         : ${database} (test: ${database}_test)`);
  console.log(`  file diganti     : ${changed.length} (lihat \`git status\`)`);
  console.log('  docs/PRD.md, docs/TASKS.md: placeholder; docs/logs/: dikosongkan');
  console.log('\nLangkah berikutnya:');
  console.log(
    '  1. Bila `.env` sudah ada, salin ulang dari `.env.example` (nilainya ikut berubah).',
  );
  console.log(
    '  2. Bila volume PostgreSQL proyek ini sudah pernah dibuat dengan nama database lama, buat ' +
      'ulang: `docker compose down -v`, lalu `docker compose up -d --wait`.',
  );
  console.log('  3. Jalankan `pnpm check`, lalu commit hasilnya.');
  console.log('  4. Isi docs/PRD.md dan docs/TASKS.md.');
}

try {
  main();
} catch (error) {
  if (!(error instanceof InitError)) throw error;
  console.error(error.message);
  process.exitCode = 1;
}
