// Port penyimpanan file (D-06). Use case hanya bergantung pada interface ini; adapternya dipilih
// lewat env `STORAGE_ADAPTER` di `create-ports.ts` (`fake` untuk test, `firebase` untuk Firebase
// Storage atau Storage Emulator).

export interface StoredFile {
  data: Buffer;
  contentType: string;
}

export interface FileStorage {
  // Menimpa file yang sudah ada di path yang sama.
  save(path: string, data: Uint8Array, options: { contentType: string }): Promise<void>;
  // `null` bila file tidak ada.
  read(path: string): Promise<StoredFile | null>;
  // Tidak error bila file tidak ada.
  delete(path: string): Promise<void>;
}

// Path relatif dengan segmen dipisah `/`, misalnya `users/<id>/avatar.png`. Tanpa `/` di awal
// atau akhir, segmen kosong, `.`/`..`, backslash, atau karakter kontrol, agar semua adapter
// menerima path yang sama dan path dari input user tidak bisa keluar dari prefix-nya.
// biome-ignore lint/suspicious/noControlCharactersInRegex: karakter kontrol memang yang ditolak.
const FORBIDDEN_CHARS = /[\\\u0000-\u001f\u007f]/;

export class InvalidFilePathError extends Error {
  constructor(path: string) {
    super(`Invalid file path: ${JSON.stringify(path)}`);
    this.name = 'InvalidFilePathError';
  }
}

export function assertValidFilePath(path: string): void {
  const valid =
    path.length > 0 &&
    path.length <= 1024 &&
    !FORBIDDEN_CHARS.test(path) &&
    path.split('/').every((segment) => segment !== '' && segment !== '.' && segment !== '..');
  if (!valid) throw new InvalidFilePathError(path);
}
