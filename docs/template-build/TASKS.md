# TASKS — Template Starter Profil A

Setiap task dikerjakan dalam satu sesi. Kriteria bertanda **(manual)** diverifikasi user: agent menjelaskan langkahnya, lalu menunggu konfirmasi sebelum mencentang.

## Fase 0 — Fondasi dan spike

- [x] T-001 Root monorepo, Biome, dan `pnpm prereq`
  - layer: infra · depends_on: - · refs: FR-01, NFR-01, D-08, D-10, D-12
  - files: `package.json`, `pnpm-workspace.yaml`, `.nvmrc`, `.gitattributes`, `.gitignore`, `.editorconfig`, `biome.json`, `scripts/prereq.mjs`, `README.md`, `docs/conventions.md` (kerangka awal)
  - done when: `pnpm install` sukses; `pnpm biome check .` bersih; `pnpm prereq` menampilkan tabel status semua prasyarat bagian 3 PRD dengan exit code 0 saat lengkap; diuji dengan Docker Desktop dimatikan (gagal dengan saran jelas) dan `.env` belum ada (menampilkan perintah salin, tidak membuat file); spike Biome (D-08) dicatat hasilnya di log

- [x] T-002 Docker Compose: PostgreSQL, Auth Emulator, Storage Emulator
  - layer: infra · depends_on: T-001 · refs: FR-02, D-13
  - files: `docker-compose.yml`, `docker/firebase-emulator/Dockerfile`, `firebase.json`, `.firebaserc`, `storage.rules`, `.env.example`, `scripts/prereq.mjs` (cek layanan opsional), `README.md`
  - done when: `docker compose up -d --wait` membuat ketiga layanan healthy; `curl http://localhost:9099/` berisi `"ready": true`; Storage Emulator merespons di port 9199; `storage.rules` menolak semua akses; waktu build pertama dan build ulang image emulator dicatat di log; `.env.example` berisi semua variabel yang dipakai sampai tahap ini

- [x] T-003 Spike kontrak: Hono → `openapi.json` → client Dart swagger_parser
  - layer: spike · depends_on: T-001 · refs: FR-10, D-01, D-02
  - files: `spikes/contract/` (sementara, dihapus di T-020)
  - done when: satu route `@hono/zod-openapi` dengan skema error bagian 5 PRD diekspor ke `openapi.json`; swagger_parser menghasilkan package Dart yang lolos `dart analyze`; satu unit test Dart men-deserialize contoh respons sukses dan error; hasil dicatat di log dengan rekomendasi tetap memakai D-02 atau pindah ke cadangan

- [x] T-004 Spike Flutter + Firebase Auth Emulator dengan FirebaseOptions dummy
  - layer: spike · depends_on: T-002 · refs: FR-12, D-04
  - files: `spikes/firebase_flutter/` (sementara, dihapus di T-020)
  - done when: `flutter analyze` bersih; aplikasi spike membaca FirebaseOptions dummy dari `--dart-define-from-file`, memanggil `useAuthEmulator`, dan menyediakan tombol daftar dan login; **(manual)** user memastikan daftar dan login berhasil di Chrome dan di Android emulator (host `10.0.2.2`), dan akun muncul di emulator (`POST http://localhost:9099/identitytoolkit.googleapis.com/v1/projects/demo-template/accounts:query` dengan header `Authorization: Bearer owner` dan body `{}`); versi Flutter dicatat di log dan README

## Fase 1 — API

- [x] T-005 Kerangka API: env, error, logger, CORS, `/health`
  - layer: api · depends_on: T-002, T-003 · refs: FR-04, NFR-04, D-03, D-13
  - files: `apps/api/package.json`, `apps/api/tsconfig.json`, `apps/api/vitest.config.ts`, `apps/api/src/app.ts`, `apps/api/src/server.ts`, `apps/api/src/core/config/env.ts`, `apps/api/src/core/http/{errors,error-codes,context,cors}.ts`, `apps/api/src/core/logger.ts`, `apps/api/src/features/system/http/health.route.ts`, `apps/api/test/unit/**`, `apps/api/test/helpers/test-app.ts`, `apps/api/test/setup/env.ts`
  - done when: `pnpm --filter api test` dan `pnpm --filter api typecheck` lulus dengan test untuk setiap kriteria FR-04, termasuk bentuk `details` (`required`, path bersarang, `_root`) dan penolakan origin di luar `CORS_ORIGINS`; `GET /health` → `200 {"status":"ok"}` saat server dijalankan

- [x] T-006 Database: Drizzle, tabel `users`, migrasi, database test
  - layer: db · depends_on: T-005 · refs: FR-05, D-13
  - files: `apps/api/drizzle.config.ts`, `apps/api/drizzle/**`, `apps/api/src/db/{client,migrate}.ts`, `apps/api/src/db/schema/{columns,users,index}.ts`, `apps/api/vitest.int.config.ts`, `apps/api/test/setup/db.ts`, `apps/api/test/int/db/schema.int.test.ts`
  - done when: `pnpm --filter api db:migrate` sukses dua kali; `pnpm --filter api test:int` lulus dan memverifikasi tabel `users`, unique `firebase_uid`, serta bahwa database utama tidak tersentuh; `drizzle-kit generate` ulang tidak menghasilkan perubahan

- [x] T-007 Autentikasi Firebase, upsert `users`, dan `GET /v1/me`
  - layer: api · depends_on: T-006 · refs: FR-06, NFR-03
  - files: `apps/api/src/core/auth/{firebase-admin,authenticate}.ts`, `apps/api/src/features/users/**`, `apps/api/test/helpers/emulator-token.ts`, `apps/api/test/int/users/**`, `apps/api/test/int/security/all-routes-require-auth.int.test.ts`
  - done when: `pnpm --filter api test:int` lulus untuk setiap kriteria FR-06 memakai token dari Auth Emulator, termasuk dua request pertama paralel; test NFR-03 mengiterasi semua route `/v1/*` yang terdaftar dan memastikan semuanya `401` tanpa token

- [x] T-008 Helper pagination cursor
  - layer: api · depends_on: T-005 · refs: FR-09
  - files: `apps/api/src/core/http/pagination.ts`, `apps/api/test/unit/core/http/pagination.test.ts`
  - done when: unit test membuktikan encode/decode cursor bolak-balik, `limit` default 20 dan batas 1–100, cursor rusak menghasilkan `422` dengan `details.cursor`, dan skema query serta respons `{ items, nextCursor }` bisa dipakai ulang oleh route mana pun

- [x] T-009 pg-boss: lifecycle, graceful shutdown, job `system.heartbeat`
  - layer: api · depends_on: T-006 · refs: FR-07, D-05
  - files: `apps/api/src/core/jobs/{boss,heartbeat.job}.ts`, `apps/api/src/server.ts`, `apps/api/test/int/jobs/**`
  - done when: `pnpm --filter api test:int` membuktikan job dikirim lalu diproses handler, pg-boss tidak start tanpa `RUN_WORKER=true`, dan urutan shutdown (berhenti menerima request, stop pg-boss, keluar) teruji lewat fungsi shutdown yang dipanggil langsung di test

- [x] T-010 Port `PushSender` dan `FileStorage` dengan adapter
  - layer: api · depends_on: T-005 · refs: FR-08, D-06
  - files: `apps/api/src/core/ports/{push-sender,file-storage}.ts`, `apps/api/src/core/ports/adapters/{fake-push,fcm-push,fake-storage,firebase-storage}.ts`, `apps/api/test/unit/core/ports/**`, `apps/api/test/int/ports/firebase-storage.int.test.ts`
  - done when: unit test untuk adapter palsu dan adapter FCM (firebase-admin di-mock) lulus; integration test menyimpan, membaca, dan menghapus file lewat Storage Emulator lulus; pemilihan adapter lewat env (`PUSH_ADAPTER`, `STORAGE_ADAPTER`) teruji

- [x] T-011 Fitur contoh notes (API)
  - layer: api · depends_on: T-007, T-008 · refs: FR-09, D-07, NFR-05, NFR-06
  - files: `apps/api/src/db/schema/notes.ts`, `apps/api/drizzle/0001_*.sql`, `apps/api/src/features/notes/{domain,usecases,infrastructure,http}/**`, `apps/api/test/unit/features/notes/**`, `apps/api/test/int/notes/**`, `apps/api/test/helpers/factories.ts`
  - done when: `pnpm --filter api test` dan `pnpm --filter api test:int` lulus untuk setiap kriteria FR-09, termasuk isolasi antar-user (`404`), pagination 25 notes tanpa duplikat, dan CHECK constraint `title`/`body` di level database; setiap use case punya unit test dengan repository palsu

## Fase 2 — Kontrak

- [x] T-012 Pipeline kontrak: `contract:generate` dan `contract:check`
  - layer: contract · depends_on: T-003, T-011 · refs: FR-10, D-01, D-02
  - files: `apps/api/scripts/export-openapi.ts`, `packages/contract/openapi.json`, `packages/contract/dart/**`, `scripts/contract.mjs`, `package.json`
  - done when: `pnpm contract:generate` memperbarui `openapi.json` dan `api_client` yang lolos `dart analyze`; `ErrorCode` muncul sebagai enum; `pnpm contract:check` lulus saat sinkron, dan terbukti gagal (dengan nama file yang tidak sinkron) setelah satu field route diubah sementara tanpa generate ulang

## Fase 3 — Flutter

- [x] T-013 Kerangka Flutter: config, DI, router, `Result`, network, pemetaan error
  - layer: app · depends_on: T-004, T-012 · refs: FR-11, D-03, D-04
  - files: `apps/app/pubspec.yaml`, `apps/app/analysis_options.yaml`, `apps/app/config/dev.json`, `apps/app/lib/{main,app}.dart`, `apps/app/lib/core/{config,di,error,network,router,theme,l10n}/**`, `apps/app/test/core/**`
  - done when: `flutter analyze` bersih dan `flutter test` lulus dengan test untuk setiap kriteria FR-11, termasuk penggantian host `10.0.2.2` di Android, pemetaan setiap `ErrorCode` ke teks Bahasa Indonesia, dan interceptor yang me-refresh token sekali saat `401`

- [x] T-014 Fitur login Flutter
  - layer: app · depends_on: T-013 · refs: FR-12, NFR-06
  - files: `apps/app/lib/features/auth/{domain,data,presentation}/**`, `apps/app/lib/core/router/**`, `apps/app/test/features/auth/**`
  - done when: `flutter analyze` bersih; `flutter test` lulus dengan unit test use case, `bloc_test` untuk Cubit login, dan widget test redirect rute terlindungi; **(manual)** user memastikan daftar, login, pesan password salah, dan logout berjalan di Chrome dan Android emulator

- [x] T-015 Fitur contoh notes (Flutter): domain dan data
  - layer: app · depends_on: T-014 · refs: FR-13, NFR-05, NFR-06
  - files: `apps/app/lib/features/notes/{domain,data}/**`, `apps/app/test/features/notes/{domain,data}/**`
  - done when: `flutter analyze` bersih; `flutter test` lulus untuk setiap use case (repository di-mock) dan untuk repository impl + mapper (data source di-mock), termasuk pemetaan `NOT_FOUND` dan `VALIDATION_ERROR` beserta `details` ke `Failure`

- [x] T-016 Fitur contoh notes (Flutter): presentation
  - layer: app · depends_on: T-015 · refs: FR-13
  - files: `apps/app/lib/features/notes/presentation/**`, `apps/app/test/features/notes/presentation/**`
  - done when: `flutter analyze` bersih; `bloc_test` untuk pagination, simpan, ubah, hapus, dan error jaringan lulus; widget test error validasi di field judul lulus; **(manual)** dengan API dan emulator berjalan, user memastikan alur daftar, buat, ubah, hapus, dan muat halaman berikutnya berjalan di Chrome dan Android emulator

## Fase 4 — Integrasi dan penyelesaian

- [x] T-017 `pnpm check` dan panduan menjalankan lokal
  - layer: infra · depends_on: T-016 · refs: FR-03, NFR-01, NFR-02
  - files: `scripts/check.mjs`, `package.json`, `README.md`
  - done when: `pnpm check` menjalankan semua langkah FR-03 dan menampilkan ringkasan; terbukti exit code bukan 0 saat satu langkah sengaja digagalkan; waktu total dicatat di log (target di bawah 5 menit); README berisi urutan dari clone sampai `pnpm check` hijau, termasuk perintah menjalankan API dan Flutter (`--web-port 8081`)

- [x] T-018 CI GitHub Actions
  - layer: infra · depends_on: T-017 · refs: FR-14
  - files: `.github/workflows/ci.yml`
  - done when: workflow menjalankan langkah yang sama dengan `pnpm check` memakai service PostgreSQL dan image emulator; **(manual)** user melakukan push ke GitHub dan memastikan workflow hijau, lalu memastikan workflow gagal pada commit uji yang merusak `contract:check` (commit uji itu kemudian di-revert)

- [x] T-019 Dockerfile API untuk produksi
  - layer: infra · depends_on: T-017 · refs: FR-15
  - files: `apps/api/Dockerfile`, `apps/api/package.json` (script `build`), `README.md`
  - done when: `docker build -f apps/api/Dockerfile .` sukses; container dijalankan dengan env lokal dan `GET /health` → `200`; `node dist/db/migrate.js` di dalam container sukses; image tidak berisi dependency dev (dibuktikan dengan daftar isi `node_modules`)

- [x] T-020 Dokumentasi final dan pembersihan
  - layer: docs · depends_on: T-018, T-019 · refs: FR-16, NFR-06
  - files: `docs/conventions.md`, `CLAUDE.md`, `README.md`, `docs/template-build/`, `spikes/` (dihapus)
  - done when: `docs/conventions.md` memuat semua konvensi bagian 3 dan 5 PRD, versi library yang dipin, dan rujukan ke file contoh untuk setiap konvensi; PRD, TASKS, dan log pembangunan template dipindah ke `docs/template-build/`; `spikes/` dihapus; `pnpm check` tetap hijau

- [x] T-021 Script `pnpm init-project <nama>`
  - layer: infra · depends_on: T-020 · refs: FR-16
  - files: `scripts/init-project.mjs`, `package.json`, `README.md`, `docs/PRD.md` dan `docs/TASKS.md` (placeholder)
  - done when: dijalankan pada salinan repo (bukan repo template itu sendiri) dengan nama `uji-proyek`, script mengganti `demo-template` menjadi `demo-uji-proyek`, nama database, dan judul README, mengganti `docs/PRD.md` dan `docs/TASKS.md` dengan placeholder, serta mengosongkan `docs/logs/`; `pnpm check` hijau di salinan itu; menjalankan script dua kali ditolak dengan pesan jelas
