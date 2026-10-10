// Pipeline kontrak (D-01, D-02): route Hono → packages/contract/openapi.json → package Dart api_client.
//
//   node scripts/contract.mjs generate   (pnpm contract:generate) menulis ulang hasil generate
//   node scripts/contract.mjs check      (pnpm contract:check) gagal bila hasil generate di repo
//                                        tidak sama dengan hasil generate dari route saat ini
//
// File Dart hasil generate tidak diformat ulang (`dart format`); keduanya dibandingkan apa adanya.
import { spawnSync } from 'node:child_process';
import { cpSync, existsSync, mkdtempSync, readdirSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const CONTRACT_DIR = join(ROOT, 'packages', 'contract');

// Semua yang ditulis generator. File lain di package (pubspec, lib/api_client.dart, test) ditulis
// tangan dan tidak dibandingkan.
const GENERATED = ['openapi.json', join('dart', 'lib', 'src', 'api')];

class StepError extends Error {}

function run(command, cwd) {
  console.log(`\n> ${command}`);
  const result = spawnSync(command, { cwd, shell: true, stdio: 'inherit' });
  if (result.status !== 0) {
    throw new StepError(`Perintah gagal (exit ${result.status ?? 'tanpa kode'}): ${command}`);
  }
}

function generateInto(contractDir) {
  const dartDir = join(contractDir, 'dart');
  run(
    `pnpm --filter api exec tsx scripts/export-openapi.ts "${join(contractDir, 'openapi.json')}"`,
    ROOT,
  );
  run('dart pub get', dartDir);
  // swagger_parser tidak menghapus file skema yang sudah tidak ada; mulai dari folder kosong.
  rmSync(join(dartDir, 'lib', 'src', 'api'), { recursive: true, force: true });
  run('dart run swagger_parser', dartDir);
  run('dart run build_runner build', dartDir);
}

// Path relatif (pemisah `/`) semua file di bawah `GENERATED`.
function listGenerated(contractDir) {
  const files = [];
  for (const entry of GENERATED) {
    const path = join(contractDir, entry);
    if (!existsSync(path)) continue;
    if (!entry.endsWith('.json')) {
      for (const file of readdirSync(path, { recursive: true, withFileTypes: true })) {
        if (file.isFile()) files.push(relative(contractDir, join(file.parentPath, file.name)));
      }
    } else {
      files.push(entry);
    }
  }
  return files.map((file) => file.split(sep).join('/')).sort();
}

function compare(committedDir, freshDir) {
  const committed = new Set(listGenerated(committedDir));
  const fresh = new Set(listGenerated(freshDir));
  const problems = [];
  for (const file of [...new Set([...committed, ...fresh])].sort()) {
    if (!fresh.has(file)) {
      problems.push(`${file} (tidak lagi dihasilkan generator)`);
    } else if (!committed.has(file)) {
      problems.push(`${file} (belum ada di repo)`);
    } else if (!readFileSync(join(committedDir, file)).equals(readFileSync(join(freshDir, file)))) {
      problems.push(`${file} (isi berbeda)`);
    }
  }
  return problems;
}

function generate() {
  generateInto(CONTRACT_DIR);
  run('dart analyze', join(CONTRACT_DIR, 'dart'));
  console.log('\ncontract:generate selesai: openapi.json dan api_client diperbarui.');
}

function check() {
  // Generate ulang di salinan sementara agar working tree tidak tersentuh. `.dart_tool` ikut
  // disalin supaya build_runner memakai cache yang sudah ada.
  const tempRoot = mkdtempSync(join(tmpdir(), 'contract-check-'));
  try {
    const freshDir = join(tempRoot, 'contract');
    cpSync(CONTRACT_DIR, freshDir, {
      recursive: true,
      filter: (source) => relative(CONTRACT_DIR, source).split(sep)[1] !== 'build',
    });
    generateInto(freshDir);

    const problems = compare(CONTRACT_DIR, freshDir);
    if (problems.length > 0) {
      console.error('\ncontract:check GAGAL. File kontrak tidak sinkron dengan route API:');
      for (const problem of problems) console.error(`  - packages/contract/${problem}`);
      console.error('\nJalankan `pnpm contract:generate`, lalu commit hasilnya.');
      process.exitCode = 1;
      return;
    }
    console.log('\ncontract:check lulus: openapi.json dan api_client sinkron dengan route API.');
  } finally {
    rmSync(tempRoot, { recursive: true, force: true });
  }
}

const commands = { generate, check };
const command = commands[process.argv[2]];
if (!command) {
  console.error('Pemakaian: node scripts/contract.mjs <generate|check>');
  process.exit(2);
}
try {
  command();
} catch (error) {
  if (!(error instanceof StepError)) throw error;
  console.error(`\n${error.message}`);
  process.exitCode = 1;
}
