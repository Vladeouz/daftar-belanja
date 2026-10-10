# Template Starter Profil A

Template untuk proyek Profil A: Flutter (web, Android, iOS) + API Hono + PostgreSQL + Firebase.
## Dokumen

| Dokumen | Isi |
| --- | --- |
| `docs/conventions.md` | Konvensi proyek (struktur, API, database, error, test, Flutter, CI) dengan rujukan ke file contoh. Wajib dibaca sebelum menulis kode. |
| `CLAUDE.md` | Aturan kerja Claude Code: satu task per sesi, branch, verifikasi, log per task. |
| `docs/PRD.md`, `docs/TASKS.md`, `docs/logs/` | Rencana, daftar task, dan log proyek (diisi saat proyek baru dimulai dari template ini). |
| `docs/template-build/` | PRD, TASKS, dan log pembangunan template ini (rujukan sejarah: alasan di balik setiap konvensi). |

Fitur `notes` di API dan Flutter adalah contoh pola lengkap dari database sampai UI, untuk ditiru lalu dihapus (lihat "Menghapus fitur contoh notes" di `docs/conventions.md`).

## Prasyarat

| Prasyarat | Wajib | Catatan |
| --- | --- | --- |
| Node.js 24 LTS | ya | versi ada di `.nvmrc` |
| pnpm 12.6.0 | ya | dipin lewat `packageManager`; aktifkan dengan `corepack enable` |
| Git | ya | |
| Docker Desktop (engine hidup) | ya | |
| Flutter stable 3.47.5 (Dart 3.13.4) | ya | versi yang juga dipakai CI; di Windows, Smart App Control dapat memblokir `dart.exe` |
| Android SDK + emulator | tidak | hanya untuk verifikasi Android |
| File `.env` | ya | salin sendiri dari `.env.example` |

**Platform iOS** disertakan di `apps/app/ios`, tetapi belum pernah di-build atau diverifikasi karena template dikembangkan di Windows (build iOS butuh macOS dan Xcode). Verifikasi web dan Android sudah dilakukan. Untuk memverifikasi iOS tanpa Mac, tambahkan job CI di runner macOS GitHub Actions (misalnya `runs-on: macos-15`) yang menjalankan `flutter build ios --simulator --dart-define-from-file=config/dev.json` di `apps/app` (lihat bagian "Flutter" di `docs/conventions.md`).

## Memulai proyek baru dari template

Buat salinan repo (misalnya repo baru dari template ini di GitHub, lalu clone), kemudian dari root salinan itu:

```sh
pnpm install
pnpm init-project <nama>
```

`<nama>` berisi huruf kecil, angka, dan tanda hubung (maksimal 25 karakter), misalnya `gym-membership`. Script ini hanya dijalankan sekali (kedua kalinya ditolak) dan:

- mengganti project Firebase `demo-template` menjadi `demo-<nama>` dan nama database `template` menjadi `<nama>` dengan `-` diganti `_` (database test `<nama>_test`), di semua file yang dilacak Git kecuali `docs/template-build/`;
- mengganti judul README ini dan `name` di `package.json`;
- membuat `docs/PRD.md` dan `docs/TASKS.md` berisi placeholder, dan mengosongkan `docs/logs/`.

`.env` tidak disentuh; bila sudah ada, salin ulang dari `.env.example`. Setelah itu ikuti langkah di bawah sampai `pnpm check` hijau, commit hasilnya, lalu isi `docs/PRD.md` dan `docs/TASKS.md`.

## Dari clone sampai `pnpm check` hijau

Perintah dijalankan dari root repo (kecuali disebut lain) dan berlaku di CMD, PowerShell, Git Bash, maupun Linux.

1. Pasang prasyarat di atas, lalu aktifkan pnpm dan pasang dependency:

   ```sh
   corepack enable
   pnpm install
   ```

2. Buat `.env` dari contohnya (sesuaikan isinya bila perlu):

   ```sh
   copy .env.example .env
   ```

   Di Git Bash atau Linux: `cp .env.example .env`.

3. Periksa prasyarat sampai semua baris wajib berstatus OK:

   ```sh
   pnpm prereq
   ```

4. Nyalakan Docker Desktop, lalu jalankan layanan lokal (build pertama image emulator butuh sekitar 5–7 menit):

   ```sh
   docker compose up -d --wait
   ```

5. Jalankan seluruh verifikasi:

   ```sh
   pnpm check
   ```

   Hijau bila ringkasan di akhir menampilkan `Semua 7 langkah OK.`

### `pnpm prereq`

`pnpm prereq` menampilkan tabel status setiap prasyarat beserta perintah perbaikannya, dan keluar dengan exit code bukan 0 bila ada prasyarat wajib yang gagal. Script ini tidak pernah membuat atau mengubah file.

> Jangan tertukar dengan `pnpm doctor`: itu perintah bawaan pnpm untuk mendiagnosa instalasi pnpm sendiri.

## `pnpm check`

Menjalankan berurutan: Biome (`pnpm lint`), typecheck API, unit test API, integration test API, `pnpm contract:check`, `flutter analyze`, dan `flutter test`. Langkah yang gagal tidak menghentikan langkah berikutnya; di akhir tampil ringkasan status dan waktu per langkah, dan exit code bukan 0 bila ada langkah yang gagal. Output langkah yang gagal ada di atas ringkasan dan juga disimpan lengkap ke `.check-logs/<waktu run>/<no>-<langkah>.log` (di-ignore Git; hapus kapan saja), yang jalurnya tampil di kolom Keterangan. Berguna untuk mendiagnosis kegagalan yang tidak selalu terulang.

- Integration test butuh layanan lokal (`docker compose up -d --wait`). Bila Docker mati, langkah itu gagal dengan pesan yang menyebut Docker.
- Waktu total sekitar 1 menit di laptop pengembang (target di bawah 5 menit), setelah dependency terpasang dan image emulator sudah ada. `contract:check` pertama kali bisa lebih lama karena `dart pub get`.
- Integration test memakai database `<POSTGRES_DB>_test` tersendiri, jadi aman dijalankan saat API sedang berjalan.
- CI (`.github/workflows/ci.yml`) menjalankan `pnpm check` yang sama pada setiap push dan pull request. Bila gagal, output langkah yang gagal tersedia sebagai artifact `check-logs` di run GitHub Actions.

## Menjalankan API dan Flutter

Butuh layanan lokal (`docker compose up -d --wait`) dan `.env`.

1. Migrasi database utama (sekali, dan setiap ada migrasi baru):

   ```sh
   pnpm --filter api db:migrate
   ```

2. Jalankan API di `http://localhost:3000` (reload otomatis saat kode berubah); cek dengan membuka `http://localhost:3000/health`:

   ```sh
   pnpm --filter api dev
   ```

3. Di terminal lain, jalankan Flutter dari folder `apps/app`:

   ```sh
   cd apps/app
   flutter run -d chrome --web-port 8081 --dart-define-from-file=config/dev.json
   ```

   Port web harus `8081`, karena hanya origin itu yang diizinkan `CORS_ORIGINS` di `.env`.

   Android emulator: nyalakan emulator, lihat id-nya dengan `flutter devices` (misalnya `emulator-5554`), lalu:

   ```sh
   flutter run -d emulator-5554 --dart-define-from-file=config/dev.json
   ```

   Di Android, host `localhost` di `config/dev.json` otomatis diganti `10.0.2.2`. Lihat juga bagian "Lingkungan Flutter dan Android" di `docs/conventions.md` sebelum build Android pertama.

Akun dibuat lewat tombol daftar di aplikasi dan disimpan di Auth Emulator (hanya di memori: hilang saat container emulator di-restart atau dibuat ulang).

## Image produksi API

`apps/api/Dockerfile` membangun image berisi hasil `pnpm --filter api build` (`dist/`), migrasi `drizzle/`, dan dependency produksi saja. Build dari root repo; isi yang dikirim ke Docker dibatasi `.dockerignore` (allowlist), jadi `.env` tidak pernah ikut:

```sh
docker build -f apps/api/Dockerfile -t profil-a/api:local .
```

Container menjalankan `node dist/server.js` di port `3000` dengan `NODE_ENV=production`. Env yang wajib sama dengan `apps/api/src/core/config/env.ts` (minimal `DATABASE_URL`, `FIREBASE_PROJECT_ID`, `CORS_ORIGINS`). Migrasi dijalankan sebagai perintah terpisah sebelum server, dengan image yang sama:

```sh
docker run --rm -e DATABASE_URL=<url> profil-a/api:local node dist/db/migrate.js
docker run -d -p 3000:3000 -e DATABASE_URL=<url> -e FIREBASE_PROJECT_ID=<project> -e CORS_ORIGINS=<origin> profil-a/api:local
```

Mencoba image dengan layanan lokal: dari dalam container, `localhost` adalah container itu sendiri, jadi host PostgreSQL dan emulator diganti `host.docker.internal`, dan `NODE_ENV` dari `.env` (`development`) dipakai karena emulator ditolak saat `production`:

```sh
docker run --rm -p 3000:3000 --env-file .env -e DATABASE_URL=postgres://template:template@host.docker.internal:5432/template -e FIREBASE_AUTH_EMULATOR_HOST=host.docker.internal:9099 -e FIREBASE_STORAGE_EMULATOR_HOST=host.docker.internal:9199 profil-a/api:local
```

Image punya `HEALTHCHECK` ke `/health`, dan `docker stop` (SIGTERM) menjalankan shutdown bertahap seperti di lokal.

## Layanan lokal

```sh
docker compose up -d --wait
```

| Service | Port | Isi |
| --- | --- | --- |
| `postgres` | 5432 | PostgreSQL 17, data disimpan di volume `postgres-data` |
| `firebase-auth` | 9099 | Firebase Auth Emulator, project `demo-template` |
| `firebase-storage` | 9199 | Firebase Storage Emulator, bucket `demo-template.appspot.com` |

- Build pertama image emulator (`docker/firebase-emulator/Dockerfile`) butuh sekitar 5–7 menit; setelah itu `up` selesai dalam hitungan detik.
- Nilai diambil dari `.env` bila ada, dengan default yang sama dengan `.env.example`.
- `firebase.json` dan `storage.rules` di-mount ke container. Setelah mengubahnya, jalankan `docker compose up -d --wait --force-recreate firebase-storage`; tidak perlu build ulang.
- `storage.rules` menolak semua akses client. API mengakses Storage lewat firebase-admin, yang tidak terikat aturan ini.
- Cek cepat: `curl http://localhost:9099/` berisi `"ready": true`.
- Berhenti: `docker compose down` (data PostgreSQL tetap ada); hapus data: `docker compose down -v`.
- `pnpm prereq` ikut menampilkan status ketiga layanan sebagai prasyarat opsional.

## Perintah

| Perintah | Fungsi |
| --- | --- |
| `pnpm prereq` | Memeriksa prasyarat lingkungan |
| `pnpm check` | Menjalankan semua verifikasi (lint, typecheck, test API, kontrak, Flutter) |
| `pnpm lint` | Lint dan cek format dengan Biome (`biome check .`) |
| `pnpm format` | Memperbaiki format dan lint yang bisa diperbaiki otomatis |
| `pnpm init-project <nama>` | Memulai proyek baru dari salinan template (sekali saja) |
| `pnpm --filter api build` | Mengompilasi API ke `apps/api/dist` (dipakai `apps/api/Dockerfile`) |
