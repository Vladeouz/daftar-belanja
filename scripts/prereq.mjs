#!/usr/bin/env node
// Memeriksa prasyarat lingkungan (PRD bagian 3) dan menampilkan tabel status.
// Script ini hanya membaca; tidak pernah membuat atau mengubah file apa pun.

import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join, win32 } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const isWindows = process.platform === 'win32';

const OK = 'OK';
const FAIL = 'GAGAL';
const WARN = 'PERINGATAN';

/** Menjalankan perintah lewat shell agar `.cmd`/`.bat` (pnpm, flutter) ikut ditemukan di Windows. */
function run(command, timeoutMs = 30_000) {
  const result = spawnSync(command, {
    shell: true,
    encoding: 'utf8',
    timeout: timeoutMs,
    windowsHide: true,
    cwd: root,
  });
  const output = `${result.stdout ?? ''}${result.stderr ?? ''}`.trim();
  return {
    ok: result.status === 0 && !result.error,
    output,
    timedOut: result.error?.code === 'ETIMEDOUT',
  };
}

function firstLine(text) {
  return text.split(/\r?\n/).find((line) => line.trim() !== '') ?? '';
}

function readPackageJson() {
  return JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));
}

function checkNode() {
  const expected = readFileSync(join(root, '.nvmrc'), 'utf8').trim();
  const major = process.versions.node.split('.')[0];
  if (major === expected) {
    return { status: OK, detail: `v${process.versions.node}` };
  }
  return {
    status: FAIL,
    detail: `v${process.versions.node}, dibutuhkan ${expected}.x`,
    fix: `Pasang Node.js ${expected} LTS (misalnya \`nvm install ${expected}\` lalu \`nvm use ${expected}\`).`,
  };
}

function checkPnpm() {
  const expected = readPackageJson()
    .packageManager.replace(/^pnpm@/, '')
    .split('+')[0];
  const fix = `Jalankan \`corepack enable\` lalu \`corepack prepare pnpm@${expected} --activate\`.`;
  const result = run('pnpm --version');
  if (!result.ok) {
    return { status: FAIL, detail: 'pnpm tidak ditemukan', fix };
  }
  const actual = firstLine(result.output);
  if (actual !== expected) {
    return { status: FAIL, detail: `${actual}, dibutuhkan ${expected}`, fix };
  }
  return { status: OK, detail: actual };
}

function checkGit() {
  const result = run('git --version');
  if (!result.ok) {
    return {
      status: FAIL,
      detail: 'git tidak ditemukan',
      fix: 'Pasang Git dari https://git-scm.com.',
    };
  }
  return { status: OK, detail: firstLine(result.output).replace(/^git version /, '') };
}

function checkDocker() {
  const cli = run('docker --version');
  if (!cli.ok) {
    return {
      status: FAIL,
      detail: 'docker tidak ditemukan',
      fix: 'Pasang Docker Desktop dari https://www.docker.com/products/docker-desktop.',
    };
  }
  const engine = run('docker version --format "{{.Server.Version}}"', 20_000);
  if (!engine.ok) {
    return {
      status: FAIL,
      detail: engine.timedOut ? 'engine tidak merespons (timeout)' : 'engine tidak berjalan',
      fix: 'Jalankan Docker Desktop dan tunggu sampai statusnya "Engine running", lalu ulangi `pnpm prereq`.',
    };
  }
  return { status: OK, detail: `engine ${firstLine(engine.output)}` };
}

/** Hasil `flutter --version --machine`, dibaca sekali lalu dipakai ulang. */
let flutterInfo;
function readFlutterInfo() {
  if (flutterInfo === undefined) {
    const flutter = run('flutter --version --machine', 120_000);
    if (!flutter.ok) {
      flutterInfo = { error: 'flutter tidak ditemukan atau gagal dijalankan' };
    } else {
      try {
        flutterInfo = JSON.parse(flutter.output.slice(flutter.output.indexOf('{')));
      } catch {
        flutterInfo = { error: 'output `flutter --version` tidak dikenali' };
      }
    }
  }
  return flutterInfo;
}

function checkFlutter() {
  const install = 'Pasang Flutter channel stable: https://docs.flutter.dev/get-started/install.';
  const info = readFlutterInfo();
  if (info.error) {
    return { status: FAIL, detail: info.error, fix: install };
  }
  if (info.channel !== 'stable') {
    return {
      status: FAIL,
      detail: `${info.frameworkVersion} (channel ${info.channel})`,
      fix: 'Pindah ke channel stable: `flutter channel stable` lalu `flutter upgrade`.',
    };
  }

  const dart = run('dart --version');
  if (!dart.ok) {
    const smartAppControl = isWindows
      ? ' Di Windows, kemungkinan besar `dart.exe` diblokir Smart App Control ' +
        '(Windows Security > App & browser control > Smart App Control). Matikan fitur itu atau izinkan dart.exe.'
      : '';
    return {
      status: FAIL,
      detail: `flutter ${info.frameworkVersion}, tetapi \`dart\` gagal dijalankan`,
      fix: `Pastikan \`dart --version\` berjalan.${smartAppControl}`,
    };
  }
  return { status: OK, detail: `${info.frameworkVersion} stable, Dart ${info.dartSdkVersion}` };
}

function androidSdkCandidates() {
  const fromEnv = [process.env.ANDROID_HOME, process.env.ANDROID_SDK_ROOT].filter(Boolean);
  const defaults = isWindows
    ? [process.env.LOCALAPPDATA && join(process.env.LOCALAPPDATA, 'Android', 'Sdk')]
    : process.platform === 'darwin'
      ? [join(homedir(), 'Library', 'Android', 'sdk')]
      : [join(homedir(), 'Android', 'Sdk')];
  return [...fromEnv, ...defaults.filter(Boolean)];
}

function findAndroidSdk() {
  return androidSdkCandidates().find((path) => existsSync(path));
}

function checkAndroid() {
  const sdk = findAndroidSdk();
  if (!sdk) {
    return {
      status: WARN,
      detail: 'Android SDK tidak ditemukan (opsional)',
      fix: 'Hanya untuk verifikasi Android: pasang Android Studio beserta SDK dan emulator.',
    };
  }
  const emulator = join(sdk, 'emulator', isWindows ? 'emulator.exe' : 'emulator');
  if (!existsSync(emulator)) {
    return {
      status: WARN,
      detail: `SDK di ${sdk}, emulator tidak ada (opsional)`,
      fix: 'Pasang "Android Emulator" lewat SDK Manager di Android Studio.',
    };
  }
  return { status: OK, detail: sdk };
}

// compileSdk plugin firebase_core dan firebase_auth (`android/local-config.gradle` di package-nya).
const FIREBASE_PLUGIN_COMPILE_SDK = 34;
// Dipakai bila FlutterExtension.kt tidak bisa dibaca; nilai dari Flutter 3.47.5.
const FLUTTER_ANDROID_DEFAULTS = { ndkVersion: '28.2.13676358', compileSdkVersion: 36 };

/** Versi NDK dan compileSdk bawaan Flutter, dibaca dari plugin Gradle di Flutter SDK. */
function flutterAndroidVersions() {
  const { flutterRoot } = readFlutterInfo();
  const file =
    flutterRoot &&
    join(flutterRoot, 'packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt');
  if (!file || !existsSync(file)) {
    return FLUTTER_ANDROID_DEFAULTS;
  }
  const source = readFileSync(file, 'utf8');
  const ndkVersion = source.match(/val ndkVersion: String = "([^"]+)"/)?.[1];
  const compileSdkVersion = Number(source.match(/val compileSdkVersion: Int = (\d+)/)?.[1]);
  return {
    ndkVersion: ndkVersion ?? FLUTTER_ANDROID_DEFAULTS.ndkVersion,
    compileSdkVersion: compileSdkVersion || FLUTTER_ANDROID_DEFAULTS.compileSdkVersion,
  };
}

function checkAndroidPackages() {
  const sdk = findAndroidSdk();
  if (!sdk) {
    return { status: WARN, detail: 'Android SDK tidak ditemukan (opsional)' };
  }
  const { ndkVersion, compileSdkVersion } = flutterAndroidVersions();
  const platforms = [...new Set([FIREBASE_PLUGIN_COMPILE_SDK, compileSdkVersion])].sort(
    (a, b) => a - b,
  );
  // Folder setengah jadi dari unduhan Gradle yang macet tidak dihitung: yang dicek file isinya.
  const missing = [];
  if (!existsSync(join(sdk, 'ndk', ndkVersion, 'source.properties'))) {
    missing.push(`ndk/${ndkVersion}`);
  }
  for (const level of platforms) {
    if (!existsSync(join(sdk, 'platforms', `android-${level}`, 'android.jar'))) {
      missing.push(`platforms/android-${level}`);
    }
  }
  const wanted = `NDK ${ndkVersion}, platform ${platforms.join(' dan ')}`;
  if (missing.length === 0) {
    return { status: OK, detail: wanted };
  }
  const bin = join(sdk, 'cmdline-tools', 'latest', 'bin');
  const androidCli = join(bin, isWindows ? 'android.exe' : 'android');
  // cmdline-tools baru: `android sdk install ndk/<versi>`; lama: `sdkmanager "ndk;<versi>"`.
  const install = existsSync(androidCli)
    ? `"${androidCli}" sdk install ${missing.join(' ')}`
    : `"${join(bin, 'sdkmanager')}" ${missing.map((name) => `"${name.replace('/', ';')}"`).join(' ')}`;
  return {
    status: WARN,
    detail: `belum terpasang: ${missing.join(', ')} (opsional)`,
    fix:
      `Pasang sebelum build Android pertama, karena Gradle bisa macet bila memasangnya sendiri: \`${install}\`, ` +
      'atau lewat SDK Manager di Android Studio. Hapus dulu folder setengah jadi bila ada.',
  };
}

/** Lokasi pub cache: `PUB_CACHE`, atau lokasi bawaan Dart. */
function pubCachePath() {
  if (process.env.PUB_CACHE) {
    return process.env.PUB_CACHE;
  }
  return isWindows
    ? process.env.LOCALAPPDATA && join(process.env.LOCALAPPDATA, 'Pub', 'Cache')
    : join(homedir(), '.pub-cache');
}

function checkPubCacheDrive() {
  const pubCache = pubCachePath();
  if (!isWindows) {
    return { status: OK, detail: pubCache };
  }
  if (!pubCache) {
    return { status: WARN, detail: 'lokasi pub cache tidak diketahui (LOCALAPPDATA kosong)' };
  }
  // `D:\` → `D:`; path UNC tetap utuh sebagai root-nya.
  const driveOf = (path) => win32.parse(win32.resolve(path)).root.replace(/\\$/, '').toUpperCase();
  const repoDrive = driveOf(root);
  if (repoDrive === driveOf(pubCache)) {
    return { status: OK, detail: pubCache };
  }
  const suggestion = `${repoDrive}\\pub-cache`;
  return {
    status: WARN,
    detail: `repo di drive ${repoDrive}, pub cache di ${pubCache}`,
    fix:
      'Bila repo dan pub cache beda drive, build Android gagal saat kompilasi Kotlin plugin ' +
      `("this and base files have different roots"). Jalankan \`setx PUB_CACHE ${suggestion}\`, ` +
      'buka terminal baru, lalu jalankan ulang `flutter pub get` di setiap proyek Flutter.',
  };
}

function checkEnvFile() {
  if (existsSync(join(root, '.env'))) {
    return { status: OK, detail: 'ada' };
  }
  const copy = isWindows
    ? '`copy .env.example .env` (CMD/PowerShell) atau `cp .env.example .env` (Git Bash)'
    : '`cp .env.example .env`';
  const note = existsSync(join(root, '.env.example'))
    ? ''
    : ' (`.env.example` belum tersedia di repo ini)';
  return {
    status: FAIL,
    detail: 'tidak ada',
    fix: `Buat sendiri dengan ${copy}, lalu sesuaikan isinya${note}.`,
  };
}

/** Status container docker compose per service, dibaca sekali lalu dipakai ulang. */
let composeServices;
function readComposeServices() {
  if (composeServices === undefined) {
    const result = run('docker compose ps -a --format json', 20_000);
    composeServices = result.ok
      ? new Map(
          result.output
            .split(/\r?\n/)
            .filter((line) => line.startsWith('{'))
            .map((line) => JSON.parse(line))
            .map((container) => [container.Service, container]),
        )
      : null;
  }
  return composeServices;
}

function checkService(service, port) {
  const fix =
    'Jalankan `docker compose up -d --wait` (build pertama image emulator butuh beberapa menit).';
  const services = readComposeServices();
  if (services === null) {
    return { status: WARN, detail: 'status tidak bisa dibaca (Docker mati?)', fix };
  }
  const container = services.get(service);
  if (!container) {
    return { status: WARN, detail: 'belum dijalankan', fix };
  }
  if (container.State !== 'running') {
    return {
      status: WARN,
      detail: container.State,
      fix: `${fix} Bila tetap gagal, lihat \`docker compose logs ${service}\`.`,
    };
  }
  if (container.Health && container.Health !== 'healthy') {
    return {
      status: WARN,
      detail: container.Health,
      fix: `Tunggu sebentar, lalu lihat \`docker compose logs ${service}\` bila tidak kunjung healthy.`,
    };
  }
  return { status: OK, detail: `healthy, port ${port}` };
}

const checks = [
  { name: 'Node.js', required: true, run: checkNode },
  { name: 'pnpm', required: true, run: checkPnpm },
  { name: 'Git', required: true, run: checkGit },
  { name: 'Docker', required: true, run: checkDocker },
  { name: 'Flutter', required: true, run: checkFlutter },
  { name: 'Android SDK', required: false, run: checkAndroid },
  { name: 'Android NDK/Platform', required: false, run: checkAndroidPackages },
  { name: 'Pub cache', required: false, run: checkPubCacheDrive },
  { name: 'File .env', required: true, run: checkEnvFile },
  // Layanan lokal opsional: prereq memeriksa lingkungan, bukan layanan yang sedang berjalan.
  { name: 'PostgreSQL', required: false, run: () => checkService('postgres', 5432) },
  { name: 'Auth Emulator', required: false, run: () => checkService('firebase-auth', 9099) },
  {
    name: 'Storage Emulator',
    required: false,
    run: () => checkService('firebase-storage', 9199),
  },
];

const rows = checks.map((check) => {
  const result = check.run();
  // Prasyarat opsional tidak pernah menggagalkan prereq.
  const status = !check.required && result.status === FAIL ? WARN : result.status;
  return { ...check, ...result, status };
});

const headers = ['Prasyarat', 'Wajib', 'Status', 'Detail'];
const table = rows.map((row) => [row.name, row.required ? 'ya' : 'tidak', row.status, row.detail]);
const widths = headers.map((header, i) =>
  Math.max(header.length, ...table.map((cells) => cells[i].length)),
);
const formatRow = (cells) =>
  cells
    .map((cell, i) => cell.padEnd(widths[i]))
    .join('  ')
    .trimEnd();

console.log('\npnpm prereq: memeriksa prasyarat lingkungan\n');
console.log(formatRow(headers));
console.log(widths.map((width) => '-'.repeat(width)).join('  '));
for (const cells of table) {
  console.log(formatRow(cells));
}

const fixes = rows.filter((row) => row.status !== OK && row.fix);
if (fixes.length > 0) {
  console.log('\nPerbaikan:');
  for (const row of fixes) {
    console.log(`- [${row.status}] ${row.name}: ${row.fix}`);
  }
}

const failed = rows.filter((row) => row.status === FAIL);
if (failed.length > 0) {
  console.log(`\n${failed.length} prasyarat wajib gagal.`);
  process.exitCode = 1;
} else {
  console.log('\nSemua prasyarat wajib terpenuhi.');
}
