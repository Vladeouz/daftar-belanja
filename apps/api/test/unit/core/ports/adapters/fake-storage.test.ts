import { describe, expect, it } from 'vitest';
import { createFakeFileStorage } from '../../../../../src/core/ports/adapters/fake-storage.js';
import { InvalidFilePathError } from '../../../../../src/core/ports/file-storage.js';

describe('createFakeFileStorage', () => {
  it('saves, reads, and deletes a file', async () => {
    const storage = createFakeFileStorage();

    await storage.save('notes/a.txt', Buffer.from('halo'), { contentType: 'text/plain' });
    const stored = await storage.read('notes/a.txt');
    expect(stored?.data.toString()).toBe('halo');
    expect(stored?.contentType).toBe('text/plain');
    expect(storage.paths()).toEqual(['notes/a.txt']);

    await storage.delete('notes/a.txt');
    await expect(storage.read('notes/a.txt')).resolves.toBeNull();
    expect(storage.paths()).toEqual([]);
  });

  it('overwrites an existing file', async () => {
    const storage = createFakeFileStorage();

    await storage.save('a.txt', Buffer.from('first'), { contentType: 'text/plain' });
    await storage.save('a.txt', Buffer.from('{}'), { contentType: 'application/json' });

    await expect(storage.read('a.txt')).resolves.toEqual({
      data: Buffer.from('{}'),
      contentType: 'application/json',
    });
  });

  it('returns null for a missing file and ignores deleting one', async () => {
    const storage = createFakeFileStorage();

    await expect(storage.read('missing.txt')).resolves.toBeNull();
    await expect(storage.delete('missing.txt')).resolves.toBeUndefined();
  });

  it('isolates stored data from caller buffers in both directions', async () => {
    const storage = createFakeFileStorage();
    const input = new Uint8Array([1, 2, 3]);

    await storage.save('a.bin', input, { contentType: 'application/octet-stream' });
    input[0] = 9;
    const first = await storage.read('a.bin');
    first?.data.fill(0);

    expect([...((await storage.read('a.bin'))?.data ?? [])]).toEqual([1, 2, 3]);
  });

  it('lists paths in sorted order', async () => {
    const storage = createFakeFileStorage();
    for (const path of ['b.txt', 'a/z.txt', 'a/b.txt']) {
      await storage.save(path, Buffer.from(''), { contentType: 'text/plain' });
    }

    expect(storage.paths()).toEqual(['a/b.txt', 'a/z.txt', 'b.txt']);
  });

  it('rejects invalid paths on every operation', async () => {
    const storage = createFakeFileStorage();

    await expect(
      storage.save('../a', Buffer.from(''), { contentType: 'text/plain' }),
    ).rejects.toBeInstanceOf(InvalidFilePathError);
    await expect(storage.read('/a')).rejects.toBeInstanceOf(InvalidFilePathError);
    await expect(storage.delete('a//b')).rejects.toBeInstanceOf(InvalidFilePathError);
  });
});
