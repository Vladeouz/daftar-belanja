# Konvensi Proyek

Dokumen ini adalah rujukan konvensi untuk manusia dan agent, dan berlaku untuk setiap proyek yang dibuat dari template ini. Isinya mencakup semua konvensi bagian 3 dan 5 PRD pembangunan template (`docs/template-build/PRD.md`) beserta yang ditemukan selama pembangunan (alasannya ada di `docs/template-build/logs/`). Setiap bagian merujuk file contoh di repo: tiru file itu sebelum menulis pola sendiri. Konvensi baru ditambahkan di sini bersamaan dengan kode yang pertama memakainya.

## Struktur repo

```
.
├── CLAUDE.md                  # aturan kerja agent
├── package.json               # script root: prereq, check, lint, format, contract:generate, contract:check, init-project
├── pnpm-workspace.yaml        # workspace apps/*, packages/*; allowBuilds
├── biome.json .editorconfig .gitattributes .nvmrc .env.example
├── docker-compose.yml docker/firebase-emulator/Dockerfile
├── firebase.json .firebaserc storage.rules
├── scripts/                   # prereq.mjs, check.mjs, contract.mjs, init-project.mjs
├── .github/workflows/ci.yml
├── docs/                      # PRD.md, TASKS.md, logs/ (proyek), conventions.md, template-build/
├── apps/api/                  # API Hono (lihat bagian API dan Clean Architecture API)
├── packages/contract/         # openapi.json + package Dart api_client (hasil generate)
└── apps/app/                  # Flutter (lihat bagian Flutter)
```

pnpm workspaces tanpa Turborepo (D-09). Paket: `api` (`apps/api`), `app` (`apps/app`, Flutter, bukan paket pnpm), dan `api_client` (`packages/contract/dart`, Dart).

## Prasyarat lingkungan

Diperiksa `pnpm prereq` (`scripts/prereq.mjs`), yang menampilkan tabel status beserta perintah perbaikan dan tidak pernah membuat atau mengubah file. Wajib: Node.js 24, pnpm versi `packageManager` (lewat `corepack enable`), Git, Docker dengan engine hidup (Docker Desktop di Windows), Flutter stable, dan file `.env` (disalin user dari `.env.example`; agent tidak membuatnya). Opsional (peringatan, bukan kegagalan): Android SDK + emulator, NDK/SDK Platform, lokasi Pub cache, dan status layanan Compose. Prasyarat baru ditambahkan ke `prereq.mjs` dan tabel Prasyarat di `README.md`.

## Versi yang dipin

Library dipin ke versi pasti (tanpa `^` atau `~`) saat pertama dipasang, lalu dicatat di sini.

| Komponen | Versi | Dipin di |
| --- | --- | --- |
| Node.js | 24 (`.nvmrc`), `engines.node` `>=24 <25` | T-001 |
| pnpm | 12.6.0 (`packageManager`) | T-001 |
| `@biomejs/biome` | 2.5.14 | T-001 |
| PostgreSQL | 17 (`postgres:17-alpine`) | T-002 |
| `firebase-tools` (image emulator) | 15.32.0, di atas `node:24-trixie-slim` + OpenJDK 21 | T-002 |
| Flutter | 3.47.5 stable (Dart 3.13.4) | T-004 |
| `hono` | 4.13.11 | T-005 |
| `@hono/zod-openapi` | 1.6.3 | T-005 |
| `@hono/node-server` | 2.1.3 | T-005 |
| `zod` | 4.6.5 | T-005 |
| `pino` | 10.3.1 | T-005 |
| `typescript` | 7.0.2 | T-005 |
| `tsx` | 4.23.15 | T-005 |
| `vitest` | 5.0.2 | T-005 |
| `@types/node` | 26.6.3 | T-005 |
| `drizzle-orm` | 0.45.3 | T-006 |
| `drizzle-kit` | 0.31.11 | T-006 |
| `pg` | 8.23.0 | T-006 |
| `@types/pg` | 8.23.1 | T-006 |
| `firebase-admin` | 14.5.0 | T-007 |
| `pg-boss` | 12.36.0 | T-009 |
| `swagger_parser` (Dart, dev) | 1.45.0 | T-012 |
| `build_runner` (Dart, dev) | 2.16.1 | T-012 |
| `json_serializable` (Dart, dev) | 6.14.1 | T-012 |
| `retrofit_generator` (Dart, dev) | 10.2.11 | T-012 |
| `test` (Dart, dev) | 1.32.0 | T-012 |
| `dio` (Dart) | 5.11.1 | T-012 |
| `retrofit` (Dart) | 4.10.0 | T-012 |
| `json_annotation` (Dart) | 4.12.0 | T-012 |
| `firebase_core` (Flutter) | 4.15.0 | T-004 (spike), T-013 |
| `firebase_auth` (Flutter) | 6.7.0 | T-004 (spike), T-013 |
| `get_it` (Flutter) | 9.3.0 | T-013 |
| `go_router` (Flutter) | 18.0.2 | T-013 |
| `equatable` (Flutter) | 3.0.0 | T-013 |
| `flutter_lints` (Flutter, dev) | 6.0.0 | T-004 (spike), T-013 |
| `mocktail` (Flutter, dev) | 1.0.5 | T-013 |
| `flutter_bloc` (Flutter) | 9.1.1 (`bloc` 9.2.1 transitif) | T-014 |
| `bloc_test` (Flutter, dev) | 10.0.0 | T-014 |

Pasang dengan `pnpm --filter <paket> add -E <nama>` agar versi langsung pasti. Paket Dart/Flutter: `flutter pub add <nama>:<versi>` (atau `flutter pub add <nama>` lalu hapus `^` di `pubspec.yaml`); `dio` di app sama persis dengan `packages/contract/dart`. Paket yang butuh build script saat install didaftarkan di `allowBuilds` pada `pnpm-workspace.yaml` (saat ini `esbuild`, dipakai `tsx` dan `vitest`); tanpa itu pnpm 12 keluar dengan `ERR_PNPM_IGNORED_BUILDS`. Build script yang tidak dibutuhkan didaftarkan dengan nilai `false` beserta alasannya di komentar (saat ini `@firebase/util` dan `protobufjs`, dependency `firebase-admin`); jangan biarkan nilai placeholder `set this to true or false` yang ditulis pnpm.

pnpm 12 menolak versi yang rilis kurang dari sehari (`minimumReleaseAge`). Bila `pnpm add` menambah `minimumReleaseAgeExclude` ke `pnpm-workspace.yaml`, batalkan perubahan itu (`pnpm-workspace.yaml`, `pnpm-lock.yaml`, `package.json`) dan pin versi sebelumnya; jangan melonggarkan policy.

## Git

- Branch `<type>/t-xxx-<ringkas>`, type: `feat`, `fix`, `chore`, `docs`, `test`.
- Commit `<type>: <ringkasan> (T-xxx)`.
- Merge ke `master` dilakukan user setelah meninjau hasil.
- `.gitattributes` memaksa LF untuk semua file teks, kecuali `*.bat` dan `*.cmd` (CRLF). `.editorconfig` mengikuti aturan yang sama.

## Script dan perintah root

- Semua script otomatisasi ditulis dalam Node (`.mjs`) di `scripts/`, bukan shell, agar berjalan sama di CMD, PowerShell, Git Bash, dan Linux CI. Contoh: `scripts/prereq.mjs`.
- Script memanggil perintah eksternal lewat `spawnSync(perintah, { shell: true })` agar `pnpm.cmd`, `flutter.bat`, dan sejenisnya ditemukan di Windows.
- Nama script di `package.json` root tidak boleh sama dengan perintah bawaan pnpm (misalnya `doctor`, `init`, `test`, `ci`), karena perintah bawaan selalu menang. Cek dengan `pnpm help <nama>`: bila keluar `unrecognized subcommand`, nama itu aman (PRD D-14).
- Nama file script sama dengan nama script-nya (`pnpm prereq` → `scripts/prereq.mjs`).
- Perintah per paket dijalankan dari root dengan `pnpm --filter <paket> <script>` (`pnpm --filter api dev`); tidak ada script root `dev`.

### `pnpm check` dan CI

- `pnpm check` (`scripts/check.mjs`) adalah satu-satunya perintah verifikasi: Biome, typecheck API, unit test API, integration test API, `contract:check`, `flutter analyze`, `flutter test`. Semua langkah selalu dijalankan walaupun ada yang gagal; ringkasan di akhir menampilkan status dan waktu per langkah, dan output lengkap langkah yang gagal disimpan di `.check-logs/<waktu run>/` (di-ignore Git). Harus hijau sebelum task dicentang.
- Langkah verifikasi baru (tool baru, paket baru) ditambahkan ke `STEPS` di `scripts/check.mjs`, bukan ke `ci.yml`.
- CI (`.github/workflows/ci.yml`) hanya menjalankan `pnpm check` pada setiap push dan pull request, dengan PostgreSQL sebagai `services` dan emulator Firebase lewat `docker compose` (image di-build dengan cache GitHub Actions). Env tidak di-set di CI: default di `apps/api/test/setup/env.ts` sudah menunjuk layanan itu. Bila gagal, output langkahnya ada di artifact `check-logs`.
- Versi Flutter di `ci.yml` diperbarui bersamaan dengan README dan tabel versi di atas. Action dipin ke major tag.
- Runner dipin ke versi image (`runs-on: ubuntu-24.04`), bukan `ubuntu-latest`. Label `latest` dipindah GitHub ke versi Ubuntu baru tanpa perubahan di repo, sehingga versi Docker, Git, dan library sistem bisa berubah diam-diam dan CI gagal tanpa ada commit yang menjelaskannya. Naikkan versi runner secara sengaja dalam commit tersendiri, lalu pastikan `pnpm check` tetap hijau.

## Layanan lokal

`docker compose up -d --wait` (`docker-compose.yml`) menjalankan:

| Service | Port | Isi |
| --- | --- | --- |
| `postgres` | 5432 | PostgreSQL 17, data di volume `postgres-data` |
| `firebase-auth` | 9099 | Auth Emulator, project `demo-template` |
| `firebase-storage` | 9199 | Storage Emulator, bucket `demo-template.appspot.com` |

- Kedua emulator memakai image `profil-a/firebase-emulator:local` dari `docker/firebase-emulator/Dockerfile` (firebase-tools dipin). Project Firebase `demo-*` (`.firebaserc`) agar emulator tidak pernah menyentuh project sungguhan.
- Nilai compose diambil dari `.env` dengan default yang sama dengan `.env.example` (`${POSTGRES_DB:-template}`), sehingga compose tetap jalan tanpa `.env` (CI).
- Setiap service punya healthcheck, sehingga `--wait` hanya selesai bila layanan benar-benar siap. Healthcheck Storage memakai list objek dengan `Bearer owner`, karena root emulator menjawab `501`.
- `firebase.json` dan `storage.rules` di-mount ke container. Setelah diubah: `docker compose up -d --wait --force-recreate firebase-storage` (tanpa build ulang). `storage.rules` menolak semua akses client; aturan per proyek ditambahkan di sana bila client mengakses Storage langsung.
- Data Auth Emulator hanya di memori (hilang saat container dibuat ulang); test membuat akun dengan email acak dan tidak membersihkan emulator.

## Lint dan format (Biome)

- Satu alat untuk lint dan format TypeScript, JavaScript, dan JSON: Biome, konfigurasi di `biome.json`.
- Aturan lint: preset `recommended`. Format: spasi 2, lebar baris 100, LF, kutip tunggal, titik koma selalu.
- Biome membaca `.gitignore` (`vcs.useIgnoreFile`), jadi file yang di-ignore Git tidak diperiksa.
- `pnpm lint` untuk memeriksa, `pnpm format` untuk memperbaiki otomatis.
- File hasil generate yang formatnya ditentukan generatornya dikecualikan lewat `files.includes` di `biome.json` (saat ini `apps/api/drizzle/meta`), agar tidak bentrok saat di-generate ulang.

## Lingkungan Flutter dan Android

Dicek oleh `pnpm prereq` sebagai prasyarat opsional (peringatan, bukan kegagalan); ditemukan di T-004, dipakai untuk `apps/app` sejak T-013.

- **Pub cache satu drive dengan repo (Windows).** Bila repo dan pub cache beda drive (misalnya repo di `D:` dan pub cache bawaan di `%LOCALAPPDATA%\Pub\Cache`), build Android gagal saat kompilasi Kotlin plugin: `Could not close incremental caches … this and base files have different roots`. Atasi di mesin, bukan di proyek: `setx PUB_CACHE D:\pub-cache`, buka terminal baru, lalu `flutter pub get` ulang. `prereq` memperingatkan bila drive repo berbeda dengan drive `PUB_CACHE` (atau lokasi bawaannya) dan menyarankan nilai `setx` yang tepat. Jangan menambah `kotlin.incremental=false` ke `apps/app/android/gradle.properties`; pengaturan itu hanya dipakai di spike T-004 (sudah dihapus).
- **NDK dan SDK Platform Android dipasang sebelum build pertama.** Gradle bisa macet bila memasangnya sendiri. Yang dibutuhkan: NDK dan `compileSdk` bawaan Flutter (dibaca `prereq` dari `FlutterExtension.kt` di Flutter SDK; Flutter 3.47.5: NDK `28.2.13676358`, platform 36) serta platform 34 untuk plugin `firebase_core` dan `firebase_auth`. Pasang dengan `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\android.exe sdk install ndk/<versi> platforms/android-<level>` (cmdline-tools lama: `sdkmanager "ndk;<versi>"`). `prereq` menganggap paket terpasang hanya bila isinya lengkap (`source.properties` untuk NDK, `android.jar` untuk platform), jadi folder setengah jadi ikut dilaporkan.

## TypeScript

- `strict` + `noUncheckedIndexedAccess`, `module`/`moduleResolution` `NodeNext`, `verbatimModuleSyntax` (`import type` untuk tipe). Konfigurasi di `apps/api/tsconfig.json`; build produksi memakai `apps/api/tsconfig.build.json` (hanya `src`, keluaran `dist/` dengan struktur sama).
- Import relatif selalu berakhiran `.js` (`import { AppError } from '../core/http/errors.js';`), walaupun file sumbernya `.ts`.
- Nama file kebab-case; akhiran menandai peran: `.route.ts`, `.job.ts`, `drizzle-<entity>-repository.ts`, `.test.ts`, `.int.test.ts`.
- Lint dan format dengan Biome (lihat di atas); typecheck `pnpm --filter api typecheck`.

## API

- Prefix `/v1` untuk semua endpoint kecuali `/health`; resource jamak; JSON camelCase; timestamp ISO 8601 UTC berakhiran `Z`; tanggal kalender `YYYY-MM-DD`.
- `src/app.ts` merakit app lewat `createApp(deps)` tanpa membaca `process.env`; `src/server.ts` satu-satunya tempat yang memanggil `loadEnv()` dan `serve()`. Test memakai `createTestApp()` (`test/helpers/test-app.ts`).
- Route didefinisikan dengan `createRoute` dari `@hono/zod-openapi` dan didaftarkan lewat fungsi `registerXxxRoutes(app)` di `features/<fitur>/http/<nama>.route.ts`. Setiap route punya `operationId`; skema yang diekspor diberi nama `.openapi('Nama')`. Contoh: `apps/api/src/features/system/http/health.route.ts`.
- Urutan middleware: `requestId` → `requestLogger` → `cors`, lalu `onError` dan `notFound`; route publik (`/health`) didaftarkan sebelum `authenticate` di `/v1/*`.
- Dependency luar (database, verifier token) masuk lewat `AppDeps`; `createApp` merakit repository dan use case (composition root). Contoh: `apps/api/src/app.ts`.

### Env

- Divalidasi Zod di `apps/api/src/core/config/env.ts`. Env salah atau hilang membuat server keluar dengan exit code 1 dan pesan yang menyebut nama variabelnya.
- Setiap variabel baru ditambahkan bersamaan ke skema `env.ts`, `.env.example`, dan `test/setup/env.ts` (default untuk test).
- `pnpm --filter api dev` dan `start` membaca `../../.env` lewat `--env-file-if-exists`; variabel yang sudah di-set di shell menang.
- `FIREBASE_PROJECT_ID` wajib. `FIREBASE_AUTH_EMULATOR_HOST` (`host:port`) opsional; bila di-set, firebase-admin memverifikasi token ke Auth Emulator. Ditolak bila `NODE_ENV=production`.
- `RUN_WORKER` opsional, hanya `true` atau `false` (tidak di-set = `false`). Lihat bagian Job.
- `PUSH_ADAPTER` (`none`/`fake`/`fcm`) dan `STORAGE_ADAPTER` (`none`/`fake`/`firebase`) opsional, default `none`; `fake` ditolak bila `NODE_ENV=production`. `FIREBASE_STORAGE_BUCKET` wajib bila `STORAGE_ADAPTER=firebase`. `FIREBASE_STORAGE_EMULATOR_HOST` (`host:port`) opsional, ditolak bila `NODE_ENV=production`. Lihat bagian Port push dan storage.
- `CORS_ORIGINS` wajib, daftar origin dipisah koma (misalnya `http://localhost:8081` untuk Flutter web). Origin lain tidak mendapat `Access-Control-Allow-Origin`. Lihat `apps/api/src/core/http/cors.ts`.

### Logger

- pino, JSON ke stdout (`apps/api/src/core/logger.ts`). Di handler pakai `c.var.log` (child logger dengan `requestId`).
- Field `authorization`/`Authorization`, `token`, `idToken`, `email`, `phone` diredaksi menjadi `[REDACTED]` sampai kedalaman 4. Field sensitif baru ditambahkan ke `SENSITIVE_KEYS` beserta test-nya.
- Log request hanya berisi method, path (tanpa query string), status, durasi, dan `requestId`. Header tidak pernah dicatat.

## Job (pg-boss)

D-05: pg-boss berjalan di proses API, hanya bila `RUN_WORKER=true`. Implementasi di `apps/api/src/core/jobs/boss.ts`, contoh job di `apps/api/src/core/jobs/heartbeat.job.ts`.

- Satu job adalah `JobDefinition` (`name`, `handler`, `cron` opsional) yang dibuat fungsi `xxxJob(deps)` di file `<nama>.job.ts`, lalu didaftarkan di array `jobs` pada `startBoss()` di `src/server.ts`. Job milik fitur ditaruh di `features/<fitur>/jobs/`; `core/jobs` hanya untuk job sistem.
- Nama queue `<area>.<aksi>` (`system.heartbeat`). Jadwal cron 5 field, zona UTC (`*/5 * * * *`).
- `startBoss()` mengembalikan `null` tanpa membuka koneksi bila `runWorker` false. Bila true: start, lalu untuk setiap job `createQueue`, `schedule` (bila ada `cron`), dan `work`. Gagal di tengah jalan menghentikan pg-boss lalu melempar ulang error; `server.ts` keluar dengan exit code 1.
- pg-boss memakai pool sendiri dari `DATABASE_URL` dan schema `pgboss` (dibuat pg-boss, bukan migrasi Drizzle). Listener `error` selalu dipasang dan menulis ke log.
- Handler menerima array job (`Job<T>[]`) dan memakai logger yang diteruskan ke fungsi job, dengan field `job` dan `jobId`.

### Shutdown

`createShutdown()` di `apps/api/src/core/shutdown.ts`, dipasang untuk `SIGINT` dan `SIGTERM` di `src/server.ts`. Urutan:

1. `server.close()`: tolak koneksi baru dan tunggu request yang sedang berjalan. Koneksi keep-alive yang idle ditutup setiap 100 ms; tanpa itu Node menunggu `keepAliveTimeout` (beberapa detik).
2. `boss.stop({ graceful: true })`: tunggu job yang sedang berjalan.
3. Tutup koneksi lain di `closers` (pool database, firebase-admin). Koneksi baru yang perlu ditutup saat shutdown ditambahkan di sini.
4. `exit(0)`; bila ada langkah yang gagal, error dicatat, langkah berikutnya tetap jalan, dan exit code 1. Sinyal kedua tidak memulai shutdown baru.

Test: `test/int/jobs/boss.int.test.ts` (start, jadwal, job diproses, `RUN_WORKER` mati), `test/int/jobs/shutdown.int.test.ts` (urutan dengan server HTTP dan pg-boss sungguhan, fungsi shutdown dipanggil langsung tanpa sinyal). Koneksi pg-boss di `pg_stat_activity` memakai `application_name` `pgboss:<id>`.

## Autentikasi

- Semua route `/v1/*` dilindungi middleware `authenticate` (`apps/api/src/core/auth/authenticate.ts`) yang dipasang sekali di `app.ts` (`app.use('/v1/*', …)`); route tidak memasang auth sendiri. Route publik hanya di luar `/v1` dan wajib didaftarkan di `PUBLIC_ROUTES` pada `test/int/security/all-routes-require-auth.int.test.ts`.
- Header `Authorization: Bearer <ID token>`. Header tidak ada atau bukan Bearer → `401` `Missing bearer token`; token tidak valid, kedaluwarsa, atau untuk project lain → `401` `Invalid or expired token`. Kegagalan verifikasi yang bukan kesalahan token (`auth/internal-error`, misalnya sertifikat Google tidak bisa diambil) → `500`.
- Verifikasi lewat port `TokenVerifier` (`core/auth/firebase-admin.ts`), implementasinya `createFirebaseTokenVerifier(auth)`. firebase-admin diinisialisasi dengan `projectId` saja (tanpa service account) lewat `createFirebaseAdmin(projectId)` dengan nama app unik.
- Setelah token valid, use case `syncUser` (`features/users/usecases/sync-user.ts`) melakukan upsert `users` (`ON CONFLICT (firebase_uid)`) dengan email lowercase, `display_name` dari klaim `name`, dan `last_seen_at`; token adalah sumber kebenaran email dan nama. Hasilnya tersedia di handler sebagai `c.var.user` (entity `User`).
- Route terautentikasi memakai `security: bearerSecurity` dan `401: errorResponse(…)` di `createRoute`. Contoh: `apps/api/src/features/users/http/me.route.ts`.

## Port push dan storage

D-06: layanan luar yang tidak punya emulator atau aturannya berbeda per proyek dipakai lewat port (interface) di `apps/api/src/core/ports/`, dengan adapter di `core/ports/adapters/`. Use case hanya mengimpor port, tidak pernah firebase-admin.

- Adapter `none` (`adapters/none.ts`) adalah default bila env adapter tidak di-set: server tetap start, tetapi setiap pemakaian port melempar `PortNotConfiguredError` yang menyebut env yang harus di-set (`PushSender is not configured: set PUSH_ADAPTER to fcm or fake`). Di route, error ini menjadi `500 INTERNAL_ERROR` dan pesannya tercatat di log. Proyek yang tidak memakai push atau storage cukup membiarkannya `none`.
- Adapter `fake` hanya untuk development dan test; `loadEnv()` menolaknya bila `NODE_ENV=production` (sama seperti host emulator), sehingga server tidak start.
- `PushSender.send({ token, title, body, data? })` (`push-sender.ts`) → `{ status: 'sent', messageId }` atau `{ status: 'invalid-token' }` (token tidak terdaftar atau formatnya salah; pemanggil menghapus token itu). Kegagalan lain dilempar. Adapter: `fake-push.ts` (mencatat pesan di `sent`, `markInvalid(token)` untuk mensimulasikan token mati) dan `fcm-push.ts` (firebase-admin messaging; tidak ada emulator FCM, jadi hanya diuji dengan mock; di produksi butuh Application Default Credentials).
- `FileStorage` (`file-storage.ts`): `save(path, data, { contentType })` menimpa file lama, `read(path)` → `{ data, contentType }` atau `null`, `delete(path)` tidak error bila file tidak ada. Adapter: `fake-storage.ts` (di memori, `paths()` untuk test) dan `firebase-storage.ts` (bucket firebase-admin; memakai Storage Emulator bila `FIREBASE_STORAGE_EMULATOR_HOST` di-set). Akses lewat firebase-admin tidak terikat `storage.rules`.
- Path file relatif dengan segmen dipisah `/` (`users/<id>/avatar.png`), divalidasi `assertValidFilePath` di setiap adapter: tanpa `/` di awal atau akhir, segmen kosong, `.`/`..`, backslash, karakter kontrol, maksimal 1024 karakter. Path tidak valid → `InvalidFilePathError` sebelum ada request ke Storage.
- Adapter dipilih dari env oleh `createPorts(env, firebaseApp)` (`core/ports/create-ports.ts`) di `src/server.ts`, lalu masuk ke `createApp` lewat `AppDeps.ports` untuk dirakit ke use case. Klien firebase-admin hanya dibuat untuk adapter yang dipakai. Server mencatat adapter yang dipilih di log `API listening`.
- Test: `createTestApp()` memakai kedua adapter palsu; test yang perlu memeriksa pesan atau file memberi `ports` sendiri. Integration test Storage Emulator di `test/int/ports/firebase-storage.int.test.ts` memakai prefix acak per run dan menghapus file-nya sendiri (emulator tidak dibersihkan).
- Layanan luar baru (email, SMS, pembayaran) mengikuti pola yang sama: port + adapter `none` (default, melempar saat dipakai) + adapter `fake` (ditolak di produksi) + adapter sungguhan + pilihan `XXX_ADAPTER` di env.

## Pagination

Helper di `apps/api/src/core/http/pagination.ts`. Contoh route: `listNotesRoute` di `apps/api/src/features/notes/http/notes.route.ts`; contoh repository: `listByUser` di `features/notes/infrastructure/drizzle-note-repository.ts`.

- Query `?limit=20&cursor=<opaque>`: pakai `PaginationQuerySchema` sebagai `request.query`, atau `PaginationQuerySchema.extend({ ... })` bila route punya filter. `limit` 1–100, default 20. Handler menerima `cursor` yang sudah di-decode (`{ createdAt, id }` atau `undefined`).
- Cursor rusak → `422 VALIDATION_ERROR` dengan `details.cursor` (`custom`, `Invalid cursor`). Hanya bentuk kanonis hasil `encodeCursor` yang diterima.
- Respons `{ items, nextCursor }` dengan skema `pageSchema(ItemSchema, '<Item>Page')`; nama kedua menjadi nama komponen OpenAPI dan kelas Dart. `nextCursor` `null` di halaman terakhir.
- Cursor adalah base64url dari `createdAt|id`, urutan `created_at DESC, id DESC`. Repository mengambil `limit + 1` baris dengan kondisi `(created_at, id) < (cursor.createdAt, cursor.id)`, lalu `buildPage(rows, limit, positionOf)` membuang baris tambahan dan membentuk `nextCursor`.
- **Presisi timestamp.** Semua timestamp berpresisi milidetik (lihat Database), sama dengan `Date`, jadi repository memberi `positionOf` nilai `createdAt` (`Date`) dari baris apa adanya dan membandingkan `(created_at, id) < (${cursor.createdAt}::timestamptz, ${cursor.id}::uuid)`. Baris yang jatuh di milidetik yang sama diurutkan `id DESC` tanpa duplikat (dijaga `test/int/notes/notes.int.test.ts` › tidak ada duplikat bila beberapa note jatuh di milidetik yang sama). Decoder cursor tetap menerima 0–6 digit pecahan.
- Index pagination per pemilik: `index(...).on(table.userId, table.createdAt.desc().nullsFirst(), table.id.desc().nullsFirst())`. `nullsFirst()` wajib: tanpa itu Drizzle menulis `DESC NULLS LAST`, yang tidak cocok dengan `ORDER BY ... DESC`, sehingga PostgreSQL tetap melakukan `Sort` (dicek dengan `EXPLAIN` di `test/int/notes/notes-schema.int.test.ts`).
- Jangan menambah `.openapi()` pada `limit`: override itu menghapus `minimum`, `maximum`, dan `default` dari OpenAPI (dijaga test).

## Database

- Drizzle ORM + `pg` (node-postgres). Skema di `apps/api/src/db/schema/`, satu file per tabel, diekspor ulang dari `schema/index.ts`. Contoh: `apps/api/src/db/schema/users.ts`.
- Tabel snake_case jamak; properti TypeScript camelCase dengan nama kolom ditulis eksplisit (`firebaseUid: text('firebase_uid')`).
- Kolom bersama dari `schema/columns.ts`: `id()` (`uuid` default `gen_random_uuid()`), `createdAt()`, `updatedAt()` (`$onUpdate`, hanya berlaku lewat `db.update()` Drizzle), `timestamptz(nama)` untuk timestamp lain. Kolom `date` memakai `mode: 'string'`.
- **Semua timestamp presisi milidetik:** `timestamptz(3)` dengan `mode: 'date'`, selalu lewat helper di `schema/columns.ts`, tidak pernah `timestamp(...)` langsung. `Date` di JavaScript hanya milidetik, jadi nilai di database, entity, respons API, dan cursor pagination selalu sama persis; nilai yang lebih presisi dibulatkan PostgreSQL ke milidetik. Dijaga `test/int/db/schema.int.test.ts` › semua kolom timestamp di schema public berpresisi milidetik (tabel baru otomatis ikut diperiksa). Akibatnya dua penulisan bisa mendapat timestamp yang sama: test yang membandingkan `updated_at` sebelum dan sesudah update mengisi nilai awal di masa lalu, bukan mengandalkan `toBeGreaterThan` antara dua `now()`.
- Constraint dan index diberi nama eksplisit `<tabel>_<kolom>_<jenis>` (`users_firebase_uid_unique`, `users_email_lowercase_check`, `notes_title_length_check`, `notes_user_id_fk`, `notes_user_id_created_at_id_index`) agar test dan penanganan error bisa merujuknya. Foreign key ditulis dengan `foreignKey({ name, columns, foreignColumns })`, bukan `.references()`, karena nama bawaan Drizzle tidak mengikuti pola ini. Enum ditulis sebagai `text` + `check`. Contoh: `apps/api/src/db/schema/notes.ts`.
- Data milik user memakai `user_id` FK ke `users.id` `ON DELETE CASCADE`. Batas panjang teks ditegakkan dengan CHECK `char_length(...)` selain skema Zod route; batas Zod sama atau lebih ketat (Zod menghitung UTF-16 code unit, `char_length` menghitung karakter), jadi input yang lolos Zod tidak pernah melanggar CHECK.
- Migrasi: ubah skema → `pnpm --filter api db:generate --name <ringkas>` → commit file `apps/api/drizzle/NNNN_<ringkas>.sql` beserta `meta/`. Migrasi yang sudah di-commit tidak diedit. `db:generate` tanpa perubahan skema harus mencetak `No schema changes`.
- `pnpm --filter api db:migrate` (`src/db/migrate.ts`) menerapkan migrasi ke `DATABASE_URL`; idempoten. Hanya butuh `DATABASE_URL` (`loadDatabaseUrl()`), bukan seluruh env server.
- Koneksi dibuat lewat `createDb(url)` dari `src/db/client.ts` (mengembalikan `{ db, pool, close }`).
- Tabel pg-boss ada di schema `pgboss`, dikelola pg-boss sendiri, bukan lewat migrasi Drizzle.

## Format error

Implementasi di `apps/api/src/core/http/errors.ts` dan `error-codes.ts`. Semua error memakai satu bentuk:

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "Request validation failed", "details": { "title": [ { "code": "too_small", "message": "Too small: expected string to have >=1 characters" } ] } } }
```

| ErrorCode | HTTP | Kapan |
| --- | --- | --- |
| `BAD_REQUEST` | 400 | JSON rusak atau request tidak bisa diproses |
| `UNAUTHENTICATED` | 401 | Header `Authorization` tidak ada, token tidak valid, atau kedaluwarsa |
| `FORBIDDEN` | 403 | User terautentikasi tetapi tidak berhak (aturan peran di proyek) |
| `NOT_FOUND` | 404 | Resource tidak ada, atau milik user lain (D-07) |
| `CONFLICT` | 409 | Pelanggaran keunikan atau state |
| `VALIDATION_ERROR` | 422 | Validasi Zod gagal pada body, path, atau query |
| `INTERNAL_ERROR` | 500 | Error tak terduga; pesan asli tidak pernah dikirim ke client |

`code` stabil dan menjadi dasar teks untuk user di Flutter (D-03). Daftar `ErrorCode` diekspor ke OpenAPI sebagai enum, sehingga client Dart punya daftar yang sama. Kode baru ditambahkan ke `error-codes.ts` (beserta status HTTP-nya), lalu `pnpm contract:generate`, lalu dipetakan di `failureCodeOf` dan `failure_messages.dart` di Flutter.

- Lempar `new AppError('NOT_FOUND', 'Note not found')` dari use case atau middleware; status HTTP diturunkan dari `code`. `message` bahasa Inggris untuk developer. `AppError` tidak membawa `details`.
- `details` hanya untuk `VALIDATION_ERROR` (`ValidationError`). Validasi Zod di route ditangani otomatis oleh `defaultHook`; validasi manual di luar route memakai `new ValidationError(validationDetails(issues, input))`.
- Kunci `details`: path digabung titik (`items.0.name`), `_root` bila tanpa path (body bukan objek, `refine` di level objek). Nilai: array `{ code, message }` dengan kode issue Zod (`invalid_type`, `too_small`, `too_big`, `invalid_format`, `custom`, …), kecuali field yang tidak dikirim (`undefined` di input mentah) memakai `{ code: 'required', message: 'Required' }`. Field yang dikirim `null` tetap `invalid_type`.
- `HTTPException` 4xx dari Hono dipetakan ke `ErrorCode` menurut status (JSON rusak → `400 BAD_REQUEST`; 4xx lain yang tidak ada di daftar → `BAD_REQUEST`). Error lain dan 5xx → `500 INTERNAL_ERROR` dengan pesan umum; error aslinya dicatat di log.
- Respons error di OpenAPI memakai `errorResponse('deskripsi')` agar semua route merujuk komponen `ErrorBody` → `ApiError` → `ErrorIssue`, `ErrorCode`.

## Test API

- Unit test di `apps/api/test/unit/`, mengikuti struktur `src/` (`src/core/http/errors.ts` → `test/unit/core/http/errors.test.ts`). Dijalankan `pnpm --filter api test`.
- Integration test di `apps/api/test/int/<area>/` dengan akhiran `.int.test.ts`, dijalankan `pnpm --filter api test:int` (butuh `docker compose up -d --wait`). Contoh: `test/int/db/schema.int.test.ts`.
- Global setup `test/setup/db.ts` membuat ulang database `<nama database DATABASE_URL>_test` (default `template_test`) setiap run dan menjalankan migrasi yang di-commit. Database utama hanya dipakai untuk `DROP`/`CREATE DATABASE`; datanya tidak disentuh. Bila PostgreSQL tidak bisa dihubungi, pesan error menyebut Docker.
- Setiap file integration test memanggil `const getDb = useTestDb();` (`test/helpers/db.ts`) di level atas: membuka pool ke database test dan men-`TRUNCATE` semua tabel `public` sebelum setiap test. File berjalan berurutan (`fileParallelism: false`).
- Pelanggaran constraint diperiksa lewat SQLSTATE dan nama constraint (`23505` unique, `23514` check, `23503` FK).
- `test/setup/env.ts` mengisi env default test tanpa menimpa nilai dari shell.
- `createTestApp()` memakai `db` yang belum terkoneksi dan `rejectAllTokens`, jadi unit test tidak butuh Docker. Integration test yang butuh login memberi `db: getDb().db` dan `tokenVerifier: createEmulatorTokenVerifier()`.
- Token login dibuat lewat Auth Emulator dengan `signUp()` / `updateAccount()` dari `test/helpers/emulator-token.ts` (email acak, emulator tidak dibersihkan). Token kedaluwarsa atau untuk project lain dibuat dengan `unsignedIdToken({ exp, aud, … })`. Contoh: `test/int/users/me.int.test.ts`.
- Test HTTP memanggil `app.request()` pada `createTestApp()`, bukan server sungguhan. Route khusus test didaftarkan di app hasil `createTestApp()` di dalam file test-nya (contoh: `test/unit/core/http/errors.test.ts`).
- Log diperiksa dengan `createLogger({ level: 'info' }, stream)` memakai `Writable` yang menampung baris JSON (contoh: `test/unit/core/logger.test.ts`).
- Setiap use case punya unit test dengan repository palsu di memori yang meniru perilaku implementasi Drizzle (pembatasan pemilik, urutan, cursor). Repository palsu fitur ditaruh di `test/unit/features/<fitur>/fake-<nama>-repository.ts` (bukan `*.test.ts`, jadi tidak dijalankan sendiri). Contoh: `test/unit/features/notes/fake-note-repository.ts`, `test/unit/features/notes/usecases/*.test.ts`.
- Unit test route memeriksa pemetaan DTO dan dokumen OpenAPI (operationId, security, status, nama skema); perilaku route yang butuh login diuji di integration test. Contoh: `test/unit/features/notes/http/notes.route.test.ts`, `test/int/notes/notes.int.test.ts`.
- Unit test yang menjalankan proses anak (`spawnSync`) memberi timeout per test lebih besar dari `timeout` proses anaknya, bukan menaikkan `testTimeout` global; start dingin `tsx` di Windows bisa lebih dari 5 detik bawaan Vitest. Contoh: `test/unit/server.test.ts`.
- Integration test yang memeriksa keadaan server PostgreSQL (`pg_stat_activity` dan sejenisnya) membatasi ke `datname = current_database()`, karena API dev bisa berjalan bersamaan di database utama. Contoh: `test/int/jobs/boss.int.test.ts`.
- Tidak ada retry otomatis untuk test yang gagal acak; cari dan perbaiki penyebabnya (output lengkap di `.check-logs/`).
- Keadaan awal integration test dibuat dengan `insertUser`, `insertNote`, `insertNotes` dari `test/helpers/factories.ts`; data yang diuji lewat HTTP tetap dibuat lewat route. Integration test yang butuh `userId` login memanggil `GET /v1/me` dulu (helper `login()` di `test/int/notes/notes.int.test.ts`).

## Clean Architecture API

Contoh lengkap: `apps/api/src/features/notes/` (fitur CONTOH yang ditiru lalu dihapus di proyek).

```
features/<fitur>/
├── domain/<entity>.ts                         # entity, input, interface repository; tanpa import Hono/Drizzle
├── usecases/<aksi>-<entity>.ts                # satu use case per file
├── infrastructure/drizzle-<entity>-repository.ts
└── http/<fitur>.route.ts                      # skema Zod, createRoute, DTO, registerXxxRoutes
```

- Arah dependency: `http` → `usecases` → `domain` ← `infrastructure`. Use case hanya mengimpor `domain`, `AppError` (`core/http/errors.ts`), port (`core/ports`), dan tipe `Page`/`CursorPosition` (`core/http/pagination.ts`); tidak pernah Hono, Drizzle, atau firebase-admin.
- Use case adalah fungsi pabrik `xxxNote({ notes })` yang mengembalikan fungsi, dengan tipe `export type XxxNote = ReturnType<typeof xxxNote>`. Dependency (repository, port, `now`) masuk lewat objek pertama agar test bisa memberi versi palsu. Contoh: `features/notes/usecases/get-note.ts`.
- Entity domain memakai `Date` untuk timestamp. Konversi ke JSON (`toISOString()`, membuang field internal seperti `userId`) hanya di `http` lewat fungsi `toXxxDto`.
- Repository dibatasi pemilik: setiap metode menerima `userId` dan memfilter `user_id` di query yang sama (bukan ambil dulu lalu cek), lalu mengembalikan `null`/`false` bila tidak ada atau milik user lain. Use case mengubahnya menjadi `AppError('NOT_FOUND', ...)` (D-07: `404`, bukan `403`).
- `createApp()` di `src/app.ts` adalah composition root: buat repository dari `db`, rakit use case, lalu `registerXxxRoutes(app, { ...useCases })`. Route menerima use case lewat parameter, bukan membuatnya sendiri.
- Route: path param `id` divalidasi `z.uuid()` (bukan UUID → `422 details.id`); body POST/PATCH memakai `request.body.required: true`; PATCH memakai skema dengan semua field opsional + `.refine()` minimal satu field (→ `details._root`); `DELETE` mengembalikan `c.body(null, 204)`. Skema request dan respons diberi nama `.openapi('Note')`, `'CreateNoteInput'`, `'UpdateNoteInput'`, `'NotePage'`.
- Teks wajib yang tidak boleh kosong memakai `.trim()` sebelum `.min()`/`.max()` (`z.string().trim().min(1).max(TITLE_MAX)`): teks berisi spasi saja → `422` `too_small`, nilai yang disimpan sudah dirapikan, dan panjang dihitung setelah dirapikan. Contoh: `Title` di `features/notes/http/notes.route.ts`, dijaga `test/int/notes/notes.int.test.ts`.

### Aturan bisnis: API vs client

- Aturan bisnis (wajib diisi, batas panjang, keunikan, hak akses, minimal satu field) ditegakkan di API: skema Zod route, use case, dan constraint database. API adalah satu-satunya sumber kebenaran dan harus aman walau client mengirim input apa pun.
- Client (Flutter) boleh menormalisasi input sebelum dikirim (misalnya `trim` judul atau email) dan boleh menampilkan validasi lokal yang sama dengan API untuk umpan balik cepat, tetapi **tidak boleh lebih ketat dari API**: input yang diterima API tidak boleh ditolak client. Bila aturan berubah, ubah API dulu; error validasi API (`details`) tetap ditampilkan per field.

### Organisasi dan tenancy (pola, belum ada di template)

D-11: template hanya mengenal "user yang login" dengan data milik user (`notes.user_id`). Proyek yang butuh organisasi, tim, atau peran memakai pola berikut. Belum ada file contohnya; tiru fitur notes dengan `user_id` diganti `organization_id`, dan catat implementasi pertamanya di sini sebagai file contoh.

- Tabel `organizations` (`id`, `name`, timestamp) dan `memberships` (`organization_id` dan `user_id`, keduanya FK `ON DELETE CASCADE`; `role` sebagai `text` + CHECK, misalnya `owner`/`admin`/`member`; UNIQUE `(organization_id, user_id)`). Data milik organisasi memakai `organization_id` FK `ON DELETE CASCADE`, dengan index pagination `(organization_id, created_at DESC, id DESC)`.
- Path bersarang `/v1/organizations/{organizationId}/<resource>`, sehingga tetap di bawah `authenticate`. Middleware keanggotaan di `/v1/organizations/:organizationId/*` membaca membership user login dan menaruhnya di context (`c.var.membership`); `organizationId` yang bukan UUID → `422 details.organizationId`.
- Bukan anggota → `404 NOT_FOUND` (sama dengan resource milik user lain, D-07). Anggota dengan peran yang tidak cukup → `403 FORBIDDEN`. Pemeriksaan peran ada di use case (`AppError('FORBIDDEN', …)`), bukan di route, agar teruji di unit test.
- Repository dibatasi organisasi dengan cara yang sama seperti dibatasi pemilik: setiap metode menerima `organizationId` dan memfilternya di query yang sama.
- Integration test minimal: bukan anggota → `404`, peran kurang → `403`, anggota organisasi lain tidak melihat data. Route baru otomatis diperiksa `all-routes-require-auth.int.test.ts`.
- Organisasi "aktif" di Flutter disimpan di state presentation (bukan di token) dan dikirim sebagai path, bukan header.

## Kontrak dan client Dart

D-01, D-02: route Hono adalah satu-satunya sumber kebenaran. `packages/contract/openapi.json` (OpenAPI 3.1) dan package Dart `api_client` di `packages/contract/dart/` adalah hasil generate yang di-commit; jangan diedit manual.

- `pnpm contract:generate` (`scripts/contract.mjs`): `apps/api/scripts/export-openapi.ts` menulis `openapi.json` dari `createApp()` (tanpa `.env`, Docker, atau koneksi database), lalu `dart pub get`, hapus `dart/lib/src/api/`, `dart run swagger_parser`, `dart run build_runner build`, dan `dart analyze`. Jalankan setiap kali route atau skema Zod berubah, lalu commit hasilnya bersama perubahan route.
- `pnpm contract:check`: generate ulang di salinan sementara (working tree tidak disentuh), lalu membandingkan byte per byte `openapi.json` dan semua file di `dart/lib/src/api/`. Gagal (exit 1) dengan daftar file yang berbeda, belum ada di repo, atau tidak lagi dihasilkan generator.
- `openapi.json` diformat Biome setelah export (lewat stdin, memakai `biome.json`), sehingga `pnpm lint` bersih dan hasilnya deterministik.
- File Dart hasil generate **tidak** diformat ulang (`dart format` tidak dijalankan pada `lib/src/api/`); `contract:check` membandingkan hasil generate apa adanya. Hasilnya deterministik selama versi generator sama, karena itu `dart/pubspec.lock` di-commit.
- Yang ditulis tangan di package: `pubspec.yaml`, `swagger_parser.yaml`, `lib/api_client.dart` (mengekspor `src/api/export.dart`), dan `test/api_client_test.dart`. Test dijalankan dengan `dart test` di `packages/contract/dart`.
- Nama komponen OpenAPI menjadi nama kelas Dart: setiap skema request, respons, dan objek bersarang yang penting diberi `.openapi('Nama')`. Tanpa nama, swagger_parser membuat nama sendiri (objek error tanpa nama menjadi kelas `Error` yang menutupi `dart:core`). Satu tag OpenAPI menjadi satu client (`NotesClient`, `UsersClient`, `SystemClient`), dirangkum `ApiClient`.
- `ErrorCode` menjadi enum Dart dengan nilai `$unknown` untuk kode yang belum dikenal (`unknown_enum_value: true`); Flutter memetakan `$unknown` ke teks umum. Respons error sampai di dio sebagai `DioException` dengan `response.data` berupa `Map`, dibaca dengan `ErrorBody.fromJson`.
- Field opsional yang `null` tidak dikirim di body request (`include_if_null: true` di `swagger_parser.yaml` → `@JsonKey(includeIfNull: false)`), karena API menolak `null` pada field `optional()` (`invalid_type`). Field wajib yang nullable (`nextCursor`, `User.email`) tetap ditulis sebagai `null`. Dijaga `packages/contract/dart/test/api_client_test.dart` dan `apps/app/test/features/notes/data/note_remote_data_source_test.dart`.
- Waktu: `build_runner` pertama ~35–45 detik (kompilasi builder; juga berlaku untuk `contract:check` bila `dart/.dart_tool` belum ada, misalnya di CI). Setelah itu `contract:check` ~6 detik karena `.dart_tool` ikut disalin ke folder sementara.

## Image produksi API

`apps/api/Dockerfile` (multi-stage di atas `node:24-trixie-slim`, pnpm lewat `corepack enable`) membangun image berisi `dist/` hasil `pnpm --filter api build`, folder `drizzle/`, dan dependency produksi saja. Cara build dan menjalankan ada di README, bagian "Image produksi API".

- Build selalu dari root repo: `docker build -f apps/api/Dockerfile -t profil-a/api:local .`
- `.dockerignore` di root berbentuk allowlist (`*` lalu `!…`), jadi `.env` dan `node_modules` lokal tidak pernah ikut. File baru yang dibutuhkan build (misalnya folder di luar `apps/api/src` dan `apps/api/drizzle`) wajib ditambahkan di sana.
- Dependency produksi baru otomatis ikut lewat `pnpm install --prod --filter api`; dependency yang hanya dipakai test atau tool masuk `devDependencies` agar tidak ikut image.
- Migrasi selalu dijalankan sebagai perintah terpisah sebelum server, dengan image yang sama: `node dist/db/migrate.js`. Server (`node dist/server.js`) tidak menjalankan migrasi sendiri.
- Image berjalan sebagai user `node` dengan `NODE_ENV=production`, sehingga host emulator dan adapter `fake` ditolak `loadEnv()`. `HEALTHCHECK` memanggil `/health` dengan `fetch` Node; `SIGTERM` menjalankan shutdown bertahap.

## Flutter

Aplikasi di `apps/app` (package `app`, platform web, Android, iOS), dibuat dengan `flutter create --empty`. Lint `flutter_lints` + `strict-casts`, `strict-inference`, `strict-raw-types`, `always_use_package_imports`, `prefer_single_quotes` (`analysis_options.yaml`); format dengan `dart format` (lebar bawaan 80). `flutter analyze` dan `flutter test` dijalankan di `apps/app`.

- **iOS belum terverifikasi.** Folder `apps/app/ios` disertakan, tetapi belum pernah di-build atau dijalankan karena template dikembangkan di Windows (build iOS butuh macOS dan Xcode); yang sudah diverifikasi hanya web dan Android. Opsi verifikasi tanpa Mac: job CI terpisah di runner macOS GitHub Actions (misalnya `runs-on: macos-15`, versi Flutter sama dengan job `check`) yang menjalankan `flutter build ios --simulator --dart-define-from-file=config/dev.json` di `apps/app`. Build simulator tidak butuh signing; menit runner macOS dihitung lebih mahal daripada Linux, jadi jalankan hanya pada pull request ke `master` atau lewat `workflow_dispatch`. Proyek yang menargetkan iOS mencatat hasil verifikasi pertamanya di sini.

```
lib/
├── main.dart                 # config → Firebase → useAuthEmulator → tunggu authStateChanges().first → configureDependencies → runApp
├── app.dart                  # MaterialApp.router: tema, locale id, router
└── core/
    ├── config/app_config.dart
    ├── di/injection.dart
    ├── error/                # failure.dart, result.dart
    ├── l10n/                 # app_locale.dart, failure_messages.dart
    ├── network/              # create_dio.dart, auth_interceptor.dart, token_provider.dart, error_mapper.dart, api_call.dart
    ├── router/app_router.dart
    └── theme/app_theme.dart
```

Arah dependency (Clean Architecture): `presentation` (widget + Cubit) → `domain` ← `data`. `domain` berisi Dart murni: tidak mengimpor Flutter, dio, firebase, atau `api_client`. State Cubit adalah sealed class Dart 3. Teks UI Bahasa Indonesia.

Fitur di `lib/features/<fitur>/` (contoh lengkap: `features/auth/`):

```
features/auth/
├── auth_dependencies.dart    # registerAuthDependencies(GetIt), dipanggil configureDependencies
├── domain/
│   ├── entities/             # auth_user.dart (Dart murni + equatable)
│   ├── repositories/         # auth_repository.dart (abstract interface class)
│   └── usecases/             # satu kelas per file, satu metode call: sign_in.dart, register.dart, sign_out.dart, watch_auth_user.dart
├── data/                     # auth_mapper.dart (SDK/DTO → entity, exception → Failure), firebase_auth_repository.dart
└── presentation/
    ├── cubit/                # <nama>_cubit.dart + <nama>_state.dart (sealed)
    ├── pages/                # satu halaman per rute
    └── widgets/
```

### Config

- D-04: nilai dibaca dari `--dart-define-from-file=config/dev.json` (`flutter run -d chrome --web-port 8081 --dart-define-from-file=config/dev.json`). Kunci: `API_BASE_URL`, `FIREBASE_PROJECT_ID` (`demo-template`), `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID` (dummy, satu nilai untuk semua platform), `USE_EMULATOR`, `AUTH_EMULATOR_HOST`, `AUTH_EMULATOR_PORT`. Tanpa `flutterfire configure` dan `google-services.json`.
- `AppConfig.fromEnvironment()` (`core/config/app_config.dart`) membaca `String.fromEnvironment`, lalu `AppConfig.fromMap()` memvalidasi. Nilai kosong atau salah → `ConfigException` yang menyebut nama kunci. Kunci baru ditambahkan bersamaan ke `config/dev.json`, `fromEnvironment`, `fromMap`, dan test-nya.
- Di Android (bukan web), host `localhost`/`127.0.0.1` di `API_BASE_URL` dan `AUTH_EMULATOR_HOST` diganti `10.0.2.2` oleh kode (`resolveHost`), bukan config terpisah per platform.
- Build debug Android mengizinkan HTTP (`android:usesCleartextTraffic="true"` hanya di `android/app/src/debug/AndroidManifest.xml`) karena API lokal dan Auth Emulator memakai HTTP.
- `useAuthEmulator` dipanggil di `main.dart` setelah `Firebase.initializeApp` dan sebelum operasi Auth apa pun. Peringatan Android `FirebaseApp failed to initialize because no default options were found` wajar.

### Result dan Failure

- Repository dan use case mengembalikan `Result<T>` (`core/error/result.dart`): sealed `Ok(value)` / `Err(failure)`, dibaca dengan `switch`. Exception tidak dilempar melewati batas repository.
- `Failure` (`core/error/failure.dart`) adalah kelas Dart murni (tanpa dio atau DTO) berisi `FailureCode`, `message` (Inggris, untuk log), dan `fieldErrors` (`Map<String, List<FieldIssue>>`, dari `details` 422 dengan kunci path yang sama: `title`, `items.0.name`, `_root`).
- `FailureCode` = setiap `ErrorCode` kontrak + `network` (gagal koneksi/timeout) + `unknown` (kode belum dikenal atau body tidak terbaca).

### Network

- Dio dibuat `createDio()` (`core/network/create_dio.dart`) dengan `baseUrl` dari config dan `AuthInterceptor`; `ApiClient` dari `api_client` memakai Dio itu.
- `AuthInterceptor` menambahkan `Authorization: Bearer <ID token>` dari `TokenProvider` (`FirebaseTokenProvider` → `currentUser.getIdToken()`) bila user login. Respons `401` → token di-refresh sekali (`forceRefresh`) dan request diulang sekali (penanda `extra['authRetried']`); `401` kedua, gagal refresh, atau user tidak login → error diteruskan.
- Repository memanggil `api_client` lewat `apiCall(() => client.notes.getNote(id: id), map: noteFromDto)` (`core/network/api_call.dart`): `DioException` → `Err(failureFromDioException(e))`. Exception lain (bug mapper) tidak ditangkap.
- `failureFromDioException` (`core/network/error_mapper.dart`) membaca body `ErrorBody` dan memetakan `ErrorCode` lewat `failureCodeOf` (switch tanpa `default`: kode baru di kontrak membuat `flutter analyze` gagal sampai dipetakan).

### Teks UI dan l10n

- Teks UI Bahasa Indonesia ditulis langsung di widget (satu bahasa, tanpa ARB). `AppLocale` (`core/l10n/app_locale.dart`) memasang locale `id` dan delegate Material/Cupertino agar teks bawaan widget juga Bahasa Indonesia.
- D-03: teks kegagalan untuk user hanya dari `failureMessage(FailureCode)` dan `fieldIssueMessage(FieldIssue)` di `core/l10n/failure_messages.dart`, dengan `genericFailureMessage` sebagai cadangan. `Failure.message` dari server tidak pernah ditampilkan.

### DI dan router

- get_it dengan registrasi manual. `configureDependencies({config, auth, container})` (`core/di/injection.dart`) mendaftarkan `AppConfig`, `FirebaseAuth`, `TokenProvider`, `Dio`, `ApiClient`, lalu memanggil `registerXxxDependencies(container)` setiap fitur. `FirebaseAuth` diberikan dari luar agar test memakai mock; test memakai `GetIt.asNewInstance()`.
- `getIt` hanya dipanggil di composition root (`main.dart`, router, `registerXxxDependencies`); widget dan Cubit menerima dependency lewat konstruktor.
- go_router: path di `AppRoutes`, rute di `createRouter({container, initialLocation})` (`core/router/app_router.dart`), rute tidak dikenal → `NotFoundPage`. `App` menerima `router` opsional untuk test.
- Registrasi: repository dan use case `registerLazySingleton`; Cubit halaman `registerFactory` dan dipasang router dengan `BlocProvider(create: (_) => c<LoginCubit>(), child: const LoginPage())`; Cubit sepanjang umur app (`AuthSessionCubit`) `registerLazySingleton` dengan `dispose`.

### Autentikasi Flutter

- Firebase Auth email/password lewat `AuthRepository` (`features/auth/domain/repositories/auth_repository.dart`); implementasi `FirebaseAuthRepository` memakai SDK Firebase langsung sebagai data source. `FirebaseAuthException.code` → `FailureCode` di `failureFromFirebaseAuth` (`features/auth/data/auth_mapper.dart`); `invalid-credential`/`wrong-password`/`user-not-found` sama-sama `invalidCredentials` (tidak membocorkan apakah akun ada).
- `FailureCode` memuat kode Firebase Auth (`invalidCredentials`, `emailAlreadyInUse`, `weakPassword`, `invalidEmail`, `tooManyRequests`) di samping kode API, sehingga semua teks kegagalan tetap di `failure_messages.dart`.
- Status login: `AuthSessionCubit` (sealed `Authenticated(user)` / `Unauthenticated`), state awal dari `currentUser`; `main.dart` menunggu `authStateChanges().first` sebelum `runApp` agar sesi tersimpan (web) sudah dipulihkan. Logout lewat `AuthSessionCubit.signOut()` (`SignOutButton`); state berubah lewat stream user, bukan langsung.
- Rute terlindungi secara default: `redirect` di `createRouter` mengarahkan semua rute selain `AppRoutes.public` (`/login`, `/register`) ke login bila belum login, dan rute publik ke beranda bila sudah login. Dievaluasi ulang setiap `AuthSessionCubit` berubah (`refreshListenable`). Rute terlindungi ditaruh di `ShellRoute` yang memasang `AuthSessionCubit` (untuk `SignOutButton`). Halaman terlindungi memasang `SignOutButton` di `AppBar.actions`.
- Form login dan daftar: `AuthForm` + `AuthFormState` (sealed `Idle`/`Submitting`/`Failed(failure)`/`Succeeded`). Validasi lokal hanya "wajib diisi"; aturan lain dari Firebase. Perpindahan halaman setelah berhasil dilakukan router, bukan halaman.
- Cubit yang menunggu `Future` memeriksa `isClosed` sebelum `emit` dan mengabaikan submit kedua saat `Submitting` (`features/auth/presentation/cubit/login_cubit.dart`).

### Fitur berbasis API (contoh: notes)

Contoh lengkap: `apps/app/lib/features/notes/` (fitur CONTOH, pasangan `apps/api/src/features/notes/`).

```
features/notes/
├── notes_dependencies.dart           # registerNotesDependencies(GetIt)
├── domain/
│   ├── entities/                     # note.dart, note_page.dart
│   ├── repositories/                 # note_repository.dart
│   └── usecases/                     # list_notes, get_note, create_note, update_note, delete_note
├── data/
│   ├── note_remote_data_source.dart  # membungkus NotesClient, mengembalikan DTO, melempar DioException
│   ├── note_mapper.dart              # DTO → entity (noteFromDto, notePageFromDto)
│   └── api_note_repository.dart      # apiCall(() => _remote.xxx(), map: ...) → Result
└── presentation/
    ├── cubit/                        # notes_list_cubit (daftar + pagination), note_form_cubit (buat/ubah/hapus)
    ├── pages/                        # notes_page.dart (/notes), note_form_page.dart (/notes/new, /notes/:id)
    └── widgets/                      # note_tile, note_form, load_more_footer, failure_view
```

- Data source satu kelas per resource di atas client hasil generate (`c<ApiClient>().notes`): menerima parameter Dart biasa, membuat DTO input (`CreateNoteInput`, `UpdateNoteInput`), dan mengembalikan DTO respons. Tidak menangkap exception.
- Repository impl memanggil data source lewat `apiCall`/`apiCallRaw`, tanpa pemetaan error per fitur: `NOT_FOUND` → `FailureCode.notFound`, `VALIDATION_ERROR` → `FailureCode.validation` dengan `fieldErrors` dari `details` (kunci `title`, `_root`, `cursor`), semuanya lewat `failureFromDioException`.
- File di `data/` mengimpor `api_client` dengan prefix (`import 'package:api_client/api_client.dart' as dto;`) karena nama DTO sama dengan entity (`dto.Note` vs `Note`). `domain/` tidak pernah mengimpor `api_client`.
- Entity memakai `DateTime` UTC dari DTO apa adanya; konversi ke waktu lokal hanya di presentation. Daftar memakai entity halaman sendiri (`NotePage`: `items`, `nextCursor`, `hasMore`).
- Parameter opsional `null` berarti "tidak dikirim": `limit` `null` = bawaan API (20), `body` `null` saat membuat = tidak dikirim (API menyimpan `''`), field `null` saat mengubah = tidak diubah.
- Use case hanya menormalisasi input (`title.trim()`) lalu meneruskan ke repository; wajib diisi, batas panjang, dan minimal satu field ditegakkan API (lihat Aturan bisnis: API vs client).

Presentation (`features/notes/presentation/`):

- **Daftar dengan pagination** (`NotesListCubit`): state sealed `Loading` / `LoadFailed(failure)` / `Loaded(items, nextCursor, loadingMore, loadMoreFailure)`. `load()` memuat halaman pertama (juga untuk "Coba lagi"); `loadMore()` memakai `nextCursor` dan diabaikan bila sudah halaman terakhir atau sedang memuat. Gagal di halaman berikutnya tidak menghapus daftar: `loadMoreFailure` tampil di baris terakhir dengan tombol "Coba lagi", tanpa coba ulang otomatis. Setelah `await`, Cubit membaca `state` lagi karena daftar bisa berubah selama menunggu.
- **Muat saat digulir:** baris terakhir `ListView.builder` (`LoadMoreFooter`) memanggil `loadMore()` setelah frame pertama ia dibangun. `ListView.builder` baru membangunnya saat digulir mendekati bawah, jadi tidak perlu `ScrollController`, dan halaman pertama yang tidak memenuhi layar langsung memuat halaman berikutnya. Jangan memanggil Cubit langsung di `build`.
- **Gagal memuat halaman** (jaringan, `NOT_FOUND`): `FailureView` menampilkan `failureMessage(code)` dan tombol "Coba lagi".
- **Form** (`NoteFormCubit`): state sealed `Loading` / `LoadFailed` / `Editing(note?, status, failure)` / `Saved(note)` / `Deleted(id)`; `note` `null` = membuat baru. Error validasi API (`failure.fieldErrors['title']`) tampil sebagai `errorText` di field-nya lewat `fieldIssueMessage`; kegagalan yang tidak punya field (jaringan, `NOT_FOUND`, `_root`) tampil di atas tombol simpan. Validasi lokal hanya "wajib diisi" dan `maxLength` sama dengan API. Hapus selalu lewat dialog konfirmasi.
- **Navigasi form ↔ daftar:** daftar membuka form dengan `context.push<NoteFormState>(AppRoutes.note(id), extra: note)`; form menutup dirinya dengan `context.pop(NoteFormSaved/NoteFormDeleted)`, lalu daftar menerapkan hasilnya (`noteSaved`, `noteDeleted`) tanpa memuat ulang dari API. Rute ubah membaca note dari `extra`; bila kosong (URL dibuka langsung atau dimuat ulang di web), router memanggil `cubit.load(id)` sehingga note diambil lewat `GetNote`.
- **Kembali ke daftar tanpa hasil → muat ulang halaman pertama.** Ada dua jalur, keduanya di `NotesPage` (`features/notes/presentation/pages/notes_page.dart`): (1) `push` dari daftar selesai tanpa state (tombol kembali, tombol kembali browser) → `cubit.load()`; (2) form dibuka lewat URL (`/notes/<id>`, `/notes/new`) sehingga daftar di bawahnya tidak memanggil `push` dan hasil `context.pop(state)` tidak sampai ke mana pun. Untuk jalur kedua, halaman daftar memantau `ModalRoute.isCurrentOf(context)` di `didChangeDependencies`: saat rutenya kembali paling atas dan form tidak dibuka lewat `_openForm`, daftar memanggil `cubit.load()`. Flag `_openedHere` mencegah muat ganda saat form dibuka dari daftar (jalur pertama sudah menanganinya). Dijaga `notes_flow_test.dart` › kembali dari form tanpa hasil, dan › dibuka lewat URL › `/notes/<id>`, simpan, kembali. Fitur lain dengan pola daftar ↔ form memakai pola yang sama.
- **Rute anak:** halaman form adalah rute anak (`new`, `:id`) dari rute daftar di dalam `ShellRoute` terlindungi, sehingga membuka URL form langsung tetap menaruh daftar di bawahnya. `new` didaftarkan sebelum `:id`. `GoRouter.optionURLReflectsImperativeAPIs = true` (di `createRouter`) agar `push` ikut mengubah URL di web.
- **Waktu:** `updatedAt.toLocal()` diformat dengan `MaterialLocalizations.formatMediumDate` (locale `id`), tanpa package `intl`.

### Test Flutter

- Test di `apps/app/test/` mengikuti struktur `lib/` (`lib/core/network/auth_interceptor.dart` → `test/core/network/auth_interceptor_test.dart`). Helper test yang bukan test tanpa akhiran `_test.dart` (contoh: `test/core/network/fake_http_adapter.dart`).
- Mock dengan `mocktail` (`class MockFirebaseAuth extends Mock implements FirebaseAuth {}`). Mock per fitur dikumpulkan di `test/features/<fitur>/mocks.dart` (`MockAuthRepository`, `MockLoginCubit extends MockCubit<AuthFormState> implements LoginCubit`).
- Use case: satu file test per use case, repository di-mock (`test/features/auth/domain/usecases/sign_in_test.dart`). Cubit: `blocTest` (`test/features/auth/presentation/cubit/login_cubit_test.dart`). Halaman: widget test dengan Cubit mock + `whenListen` (`test/features/auth/presentation/pages/login_page_test.dart`).
- Router: widget test dengan wiring fitur asli (`registerAuthDependencies` pada `GetIt.asNewInstance()`) dan repository diganti fake dalam memori (`test/features/auth/fake_auth_repository.dart`), lalu `App(router: createRouter(container: c))` (`test/core/router/app_router_test.dart`).
- HTTP diuji lewat Dio sungguhan dengan `FakeHttpAdapter` (mencatat request, menjawab per request), bukan mock Dio. Contoh: `test/core/network/auth_interceptor_test.dart`, `test/core/network/error_mapper_test.dart`.
- Fitur berbasis API: use case dengan repository di-mock (`test/features/notes/domain/usecases/*_test.dart`); repository impl dengan data source di-mock yang melempar `DioException.badResponse` berisi body error standar (`test/features/notes/data/api_note_repository_test.dart`); data source dengan `NotesClient` asli + `FakeHttpAdapter` untuk memeriksa method, path, query, dan body request (`test/features/notes/data/note_remote_data_source_test.dart`). Fixture entity dan JSON (`testNote`, `noteJson`, `noteNo(i)`) di `test/features/notes/mocks.dart`.
- Presentation fitur berbasis API: Cubit dengan use case di-mock (`test/features/notes/presentation/cubit/*_test.dart`); halaman dengan Cubit mock (`pages/*_test.dart`). Halaman yang menutup dirinya dengan `context.pop(hasil)` dipasang di atas `GoRouter` kecil di dalam test agar hasilnya bisa diperiksa (`note_form_page_test.dart`). Error di field diperiksa lewat `TextField.decoration.errorText` field itu, bukan sekadar teks ada di layar. Halaman dengan indikator berputar tidak memakai `pumpAndSettle` (tidak pernah selesai).
- Alur fitur lengkap lewat router, Cubit, dan use case asli dengan repository palsu yang meniru API (`test/features/notes/fake_note_repository.dart`, `test/features/notes/presentation/notes_flow_test.dart`). Test router yang membuka beranda juga mendaftarkan fitur notes dengan repository palsu itu.
- Test `config/dev.json` membaca file aslinya, jadi kunci yang hilang terdeteksi (`test/core/config/app_config_test.dart`).

## Menghapus fitur contoh notes

Fitur `notes` ada untuk ditiru (NFR-06). Hapus setelah fitur pertama proyek berdiri dan sudah menggantikannya sebagai contoh, dalam satu task tersendiri:

1. **API:** hapus `apps/api/src/features/notes/`, `src/db/schema/notes.ts` beserta ekspornya di `schema/index.ts`, dan wiring notes di `src/app.ts`. Buat migrasi baru dengan `pnpm --filter api db:generate --name drop_notes` (migrasi lama tidak diedit atau dihapus).
2. **Test API:** hapus `test/unit/features/notes/` dan `test/int/notes/`, `insertNote`/`insertNotes` di `test/helpers/factories.ts`, dan `notes.created_at` di `test/int/db/schema.int.test.ts`. Data contoh `notes/...` di test port (`test/unit/core/ports/`, `test/int/ports/`) hanya string, boleh dibiarkan.
3. **Kontrak:** `pnpm contract:generate`, lalu sesuaikan `packages/contract/dart/test/api_client_test.dart`.
4. **Flutter:** hapus `lib/features/notes/` dan `test/features/notes/`, `registerNotesDependencies` di `core/di/injection.dart`, rute notes di `core/router/app_router.dart` (arahkan `AppRoutes.home` ke beranda fitur proyek), dan bagian notes di `test/core/di/injection_test.dart`, `test/core/router/app_router_test.dart`, `test/core/network/auth_interceptor_test.dart`, `test/core/network/error_mapper_test.dart`.
5. **Dokumen:** ganti rujukan file contoh notes di dokumen ini dengan file fitur proyek yang setara.
6. `git grep -i note` untuk sisa rujukan, lalu `pnpm check` hijau.
