import { assertValidFilePath, type FileStorage, type StoredFile } from '../file-storage.js';

// Adapter palsu di memori untuk test. Isi hilang saat proses berhenti.
export interface FakeFileStorage extends FileStorage {
  // Path yang tersimpan, terurut.
  paths(): string[];
}

export function createFakeFileStorage(): FakeFileStorage {
  const files = new Map<string, StoredFile>();

  return {
    paths: () => [...files.keys()].sort(),
    async save(path, data, { contentType }) {
      assertValidFilePath(path);
      // Disalin agar perubahan buffer pemanggil tidak mengubah isi yang tersimpan.
      files.set(path, { data: Buffer.from(data), contentType });
    },
    async read(path) {
      assertValidFilePath(path);
      const file = files.get(path);
      return file ? { data: Buffer.from(file.data), contentType: file.contentType } : null;
    },
    async delete(path) {
      assertValidFilePath(path);
      files.delete(path);
    },
  };
}
