import { describe, expect, it, vi } from 'vitest';
import {
  type Bucket,
  createFirebaseFileStorage,
} from '../../../../../src/core/ports/adapters/firebase-storage.js';
import { InvalidFilePathError } from '../../../../../src/core/ports/file-storage.js';

// Bucket palsu untuk jalur yang sulit dipicu di emulator. Jalur normal diuji ke Storage Emulator
// di test/int/ports/firebase-storage.int.test.ts.
function bucketWith(file: Record<string, (...args: unknown[]) => Promise<unknown>>) {
  const bucket = { file: vi.fn(() => file) };
  return { bucket, storage: createFirebaseFileStorage(bucket as unknown as Bucket) };
}

describe('createFirebaseFileStorage', () => {
  it('uploads in a single request with the content type', async () => {
    const save = vi.fn(async () => undefined);
    const { bucket, storage } = bucketWith({ save });

    await storage.save('a/b.txt', new Uint8Array([104, 105]), { contentType: 'text/plain' });

    expect(bucket.file).toHaveBeenCalledWith('a/b.txt');
    expect(save).toHaveBeenCalledWith(Buffer.from('hi'), {
      contentType: 'text/plain',
      resumable: false,
    });
  });

  it('falls back to application/octet-stream when the object has no content type', async () => {
    const { storage } = bucketWith({
      download: async () => [Buffer.from('x')],
      getMetadata: async () => [{}],
    });

    await expect(storage.read('a.bin')).resolves.toEqual({
      data: Buffer.from('x'),
      contentType: 'application/octet-stream',
    });
  });

  it('rethrows read errors other than 404', async () => {
    const error = Object.assign(new Error('forbidden'), { code: 403 });
    const { storage } = bucketWith({
      download: async () => {
        throw error;
      },
      getMetadata: async () => [{}],
    });

    await expect(storage.read('a.txt')).rejects.toBe(error);
  });

  it('deletes with ignoreNotFound', async () => {
    const del = vi.fn(async () => undefined);
    const { storage } = bucketWith({ delete: del });

    await storage.delete('a.txt');

    expect(del).toHaveBeenCalledWith({ ignoreNotFound: true });
  });

  it('rejects invalid paths without touching the bucket', async () => {
    const { bucket, storage } = bucketWith({});

    await expect(
      storage.save('/a', Buffer.from(''), { contentType: 'text/plain' }),
    ).rejects.toBeInstanceOf(InvalidFilePathError);
    await expect(storage.read('a/../b')).rejects.toBeInstanceOf(InvalidFilePathError);
    await expect(storage.delete('')).rejects.toBeInstanceOf(InvalidFilePathError);
    expect(bucket.file).not.toHaveBeenCalled();
  });
});
