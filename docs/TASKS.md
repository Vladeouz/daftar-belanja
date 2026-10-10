# TASKS — daftar-belanja

Setiap task dikerjakan dalam satu sesi. Kriteria bertanda **(manual)** diverifikasi user: agent menjelaskan langkahnya, lalu menunggu konfirmasi sebelum mencentang.

## Fase 1 — API

- [x] T-001 Fitur shopping (API): tabel, CRUD, filter status, nama unik
  - layer: api · depends_on: - · refs: FR-01, FR-02, FR-03, NFR-01, NFR-02, D-01
  - files: ikuti struktur fitur di `docs/conventions.md`
  - done when: setiap kriteria FR-01 sampai FR-03 terbukti oleh test; endpoint baru tercakup test keamanan route yang sudah ada; `pnpm check` hijau

- [x] T-002 Aksi hapus barang yang sudah dibeli (API)
  - layer: api · depends_on: T-001 · refs: FR-04, NFR-01
  - files: ikuti struktur fitur di `docs/conventions.md`
  - done when: setiap kriteria FR-04 terbukti oleh test; `pnpm check` hijau

## Fase 2 — Flutter

- [x] T-003 Fitur shopping (Flutter): domain dan data
  - layer: app · depends_on: T-002 · refs: FR-05, NFR-02
  - files: ikuti struktur fitur di `docs/conventions.md`
  - done when: setiap use case dan repository teruji, termasuk isi request yang benar-benar dikirim untuk tambah, ubah sebagian field, dan hapus yang sudah dibeli, serta pemetaan `CONFLICT` ke `Failure`; `pnpm check` hijau

- [x] T-004 Fitur shopping (Flutter): presentation
  - layer: app · depends_on: T-003 · refs: FR-05
  - files: ikuti struktur fitur di `docs/conventions.md`
  - done when: perilaku FR-05 teruji dengan `bloc_test` dan widget test; `pnpm check` hijau; **(manual)** user memastikan semua kriteria FR-05 di Chrome dan Android emulator

## Fase 3 — Pembersihan

- [x] T-005 Hapus fitur contoh notes
  - layer: api, app · depends_on: T-004 · refs: FR-06, D-02
  - files: sesuai panduan "Menghapus fitur contoh notes" di `docs/conventions.md`
  - done when: kriteria FR-06 terbukti; `pnpm check` hijau; **(manual)** user memastikan login lalu daftar belanja tetap berjalan di Chrome

## Fase 4 — Perbaikan

- [ ] T-006 Login web tetap memakai Auth Emulator setelah `flutter run` diulang
  - layer: app · depends_on: T-005 · refs: FR-05
  - files: `apps/app/lib/main.dart` dan/atau perintah run di `README.md` dan `docs/conventions.md`
  - done when: penyebab dan solusi tercatat di log (spike); `pnpm check` hijau; **(manual)** di Chrome: login, hentikan `flutter run`, jalankan lagi, lalu logout, login, dan register berjalan tanpa menghapus profil Chrome

- [ ] T-007 Catat pesan kegagalan asli di mode debug
  - layer: app · depends_on: T-005 · refs: D-03
  - files: `apps/app/lib/core/` (titik pembuatan `Failure` atau Cubit form), test terkait
  - done when: `Failure.message` (misalnya `firebase_auth/...: API key not valid`) tercatat di konsol saat mode debug dan tidak di mode rilis, teruji unit test; teks untuk user tetap dari `failure_messages.dart` (D-03); `pnpm check` hijau
