# Aturan kerja untuk Claude Code

## Dokumen

- `docs/PRD.md` dan `docs/TASKS.md`: rencana dan daftar task proyek. Log per task di `docs/logs/`.
- `docs/conventions.md`: konvensi yang WAJIB diikuti, dengan rujukan ke file contoh untuk setiap konvensi. Tiru pola file contoh itu sebelum menulis pola sendiri.
- `docs/template-build/`: PRD, TASKS, dan log pembangunan template ini. Hanya rujukan sejarah (alasan sebuah konvensi dipilih), bukan task untuk dikerjakan. Pengecualian: bila `docs/TASKS.md` belum ada, template masih dibangun; ambil task dari `docs/template-build/TASKS.md` dan tulis log ke `docs/template-build/logs/`.

## Di awal setiap sesi

- Baca `docs/PRD.md`, `docs/conventions.md`, dan log task terakhir di `docs/logs/`.
- Ambil task berikutnya dari `docs/TASKS.md`: task pertama yang belum dicentang dan semua `depends_on`-nya sudah dicentang.
- Sebelum mulai, periksa apakah sudah ada branch untuk task itu (`git branch --list "*t-xxx*"`). Jika ada, jangan mengerjakan ulang; laporkan ke user dan tanyakan apakah branch itu perlu digabung dulu.

## Mengerjakan task

- Kerjakan SATU task per sesi. Setelah task selesai atau terhenti, berhenti dan lapor, lalu tunggu instruksi user.
- Buat branch baru dari `master` bernama `<type>/t-xxx-<ringkas>` (type: feat, fix, chore, docs, test). Pesan commit: `<type>: <ringkasan> (T-xxx)`. Jangan merge ke `master`; merge dilakukan user setelah meninjau hasilnya.
- Ikuti `docs/conventions.md` dan konvensi di PRD. Jika konvensi belum mengatur sesuatu, pilih yang paling sederhana, catat di log sebagai keputusan mandiri, dan usulkan agar ditambahkan ke `docs/conventions.md`.
- Hanya sentuh file yang relevan dengan task. Jika perlu membuat file di luar daftar `files`, sebutkan beserta alasannya di log.
- Jangan membuat atau mengubah `.env` dan secret apa pun. Jika dibutuhkan, minta user melakukannya.
- Jangan mengubah keputusan di bagian Assumptions & Decisions PRD atau kriteria *done when* tanpa persetujuan user. Jika ada kendala, jelaskan dan tawarkan pilihan beserta konsekuensinya.

## Verifikasi

- Centang task di `docs/TASKS.md` hanya setelah SEMUA kriteria *done when* terbukti. Jalankan ulang seluruh kriteria dari awal sebelum mencentang, bukan hanya bagian yang terakhir diperbaiki.
- Untuk kriteria bertanda **(manual)**, tuliskan langkah verifikasi yang jelas untuk user, lalu tunggu konfirmasinya.
- Jika ada kriteria yang tidak bisa dipenuhi, jangan mencentang. Laporkan penyebabnya dengan jujur.
- `pnpm check` harus hijau sebelum task apa pun dicentang. Bila ada langkah yang gagal, output lengkapnya ada di `.check-logs/`.

## Log per task

Setelah menyelesaikan atau menghentikan task, tulis `docs/logs/T-xxx.md` dan commit bersama task-nya, dengan bagian:

- **Status** dan nama branch.
- **Ringkasan** pekerjaan.
- **Verifikasi:** tabel perintah dan hasilnya, dipetakan ke setiap kriteria *done when*.
- **File yang diubah.**
- **Keputusan yang diambil sendiri**, beserta alasannya.
- **Hasil spike** (khusus task spike): berhasil atau tidak, dan rekomendasi untuk keputusan terkait di PRD.
- **Kendala.**
- **Task berikutnya.**

## Lingkungan

- Mesin pengembang memakai Windows. Semua script otomatisasi ditulis dalam Node (`.mjs`), bukan shell. Hindari heredoc untuk menulis banyak file; tulis file satu per satu.
- Layanan lokal berjalan lewat Docker Desktop. Jika Docker tidak merespons, minta user menyalakannya; jangan mencoba mengakalinya.

## Fitur contoh

- Fitur `notes` (API dan Flutter) adalah CONTOH: tiru polanya untuk fitur baru, lalu hapus dalam task tersendiri setelah fitur proyek pertama menggantikannya sebagai contoh (langkahnya di `docs/conventions.md`, bagian "Menghapus fitur contoh notes"). Jangan menambah perilaku proyek ke fitur `notes`.
