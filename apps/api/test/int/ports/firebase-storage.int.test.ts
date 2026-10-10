import { randomBytes, randomUUID } from 'node:crypto';
import { getStorage } from 'firebase-admin/storage';
import { afterAll, describe, expect, it } from 'vitest';
import { createFirebaseAdmin } from '../../../src/core/auth/firebase-admin.js';
import { loadEnv } from '../../../src/core/config/env.js';
import { createFirebaseFileStorage } from '../../../src/core/ports/adapters/firebase-storage.js';
import { createPorts } from '../../../src/core/ports/create-ports.js';
import { InvalidFilePathError } from '../../../src/core/ports/file-storage.js';

// Storage Emulator lokal (docker compose, port 9199) lewat FIREBASE_STORAGE_EMULATOR_HOST dari
// test/setup/env.ts. Emulator tidak dibersihkan antar-run, jadi setiap run memakai prefix acak
// dan menghapus file-nya sendiri.
const env = loadEnv();
const firebase = createFirebaseAdmin(env.FIREBASE_PROJECT_ID);
const bucket = getStorage(firebase.app).bucket(env.FIREBASE_STORAGE_BUCKET);
const storage = createFirebaseFileStorage(bucket);
const prefix = `int-test/${randomUUID()}`;

afterAll(async () => {
  await bucket.deleteFiles({ prefix: `${prefix}/` });
  await firebase.close();
});

describe('createFirebaseFileStorage (Storage Emulator)', () => {
  it('runs against the emulator', () => {
    expect(process.env.STORAGE_EMULATOR_HOST).toBe(
      `http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}`,
    );
  });

  it('saves, reads, and deletes a file', async () => {
    const path = `${prefix}/notes/a.bin`;
    // Byte acak (bukan UTF-8 yang valid) membuktikan isi biner tidak berubah.
    const data = randomBytes(2048);

    await storage.save(path, data, { contentType: 'application/octet-stream' });
    const [exists] = await bucket.file(path).exists();
    expect(exists).toBe(true);

    const stored = await storage.read(path);
    expect(stored?.contentType).toBe('application/octet-stream');
    expect(stored?.data.equals(data)).toBe(true);

    await storage.delete(path);
    await expect(storage.read(path)).resolves.toBeNull();
    expect((await bucket.file(path).exists())[0]).toBe(false);
  });

  it('overwrites an existing file, including its content type', async () => {
    const path = `${prefix}/overwrite.txt`;

    await storage.save(path, Buffer.from('first'), { contentType: 'text/plain' });
    await storage.save(path, Buffer.from('{"second":true}'), { contentType: 'application/json' });

    const stored = await storage.read(path);
    expect(stored?.data.toString()).toBe('{"second":true}');
    expect(stored?.contentType).toBe('application/json');
  });

  it('returns null when reading a file that does not exist', async () => {
    await expect(storage.read(`${prefix}/missing.txt`)).resolves.toBeNull();
  });

  it('does not fail when deleting a file that does not exist', async () => {
    await expect(storage.delete(`${prefix}/missing.txt`)).resolves.toBeUndefined();
  });

  it('rejects an invalid path before calling Storage', async () => {
    await expect(
      storage.save(`${prefix}/../escape.txt`, Buffer.from('x'), { contentType: 'text/plain' }),
    ).rejects.toBeInstanceOf(InvalidFilePathError);
    expect((await bucket.file('int-test/escape.txt').exists())[0]).toBe(false);
  });
});

describe('createPorts with STORAGE_ADAPTER=firebase', () => {
  it('stores files in the configured bucket on the emulator', async () => {
    const { fileStorage } = createPorts(
      {
        PUSH_ADAPTER: 'fake',
        STORAGE_ADAPTER: 'firebase',
        FIREBASE_STORAGE_BUCKET: env.FIREBASE_STORAGE_BUCKET,
      },
      firebase.app,
    );
    const path = `${prefix}/via-ports.txt`;

    await fileStorage.save(path, Buffer.from('hello'), { contentType: 'text/plain' });

    const [content] = await bucket.file(path).download();
    expect(content.toString()).toBe('hello');
  });
});
