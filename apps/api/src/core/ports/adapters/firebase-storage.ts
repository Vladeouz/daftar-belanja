import type { Storage } from 'firebase-admin/storage';
import { assertValidFilePath, type FileStorage } from '../file-storage.js';

export type Bucket = ReturnType<Storage['bucket']>;

// Error dari @google-cloud/storage membawa status HTTP di `code`.
function isNotFound(err: unknown): boolean {
  return typeof err === 'object' && err !== null && (err as { code?: unknown }).code === 404;
}

// Adapter Firebase Storage lewat firebase-admin (`getStorage(app).bucket(nama)`). Bila
// `FIREBASE_STORAGE_EMULATOR_HOST` di-set, firebase-admin memakai Storage Emulator tanpa
// kredensial. Akses lewat firebase-admin tidak terikat `storage.rules`.
export function createFirebaseFileStorage(bucket: Bucket): FileStorage {
  return {
    async save(path, data, { contentType }) {
      assertValidFilePath(path);
      // File yang dipakai API umumnya kecil; upload sekali kirim lebih sederhana dari resumable.
      await bucket.file(path).save(Buffer.from(data), { contentType, resumable: false });
    },
    async read(path) {
      assertValidFilePath(path);
      const file = bucket.file(path);
      try {
        const [[data], [metadata]] = await Promise.all([file.download(), file.getMetadata()]);
        return { data, contentType: metadata.contentType ?? 'application/octet-stream' };
      } catch (err) {
        if (isNotFound(err)) return null;
        throw err;
      }
    },
    async delete(path) {
      assertValidFilePath(path);
      await bucket.file(path).delete({ ignoreNotFound: true });
    },
  };
}
