import { describe, expect, it } from 'vitest';
import {
  createNoneFileStorage,
  createNonePushSender,
  PortNotConfiguredError,
} from '../../../../../src/core/ports/adapters/none.js';

describe('createNonePushSender', () => {
  it('fails on send with a message naming PUSH_ADAPTER', async () => {
    const push = createNonePushSender();

    const result = push.send({ token: 'device-1', title: 't', body: 'b' });

    await expect(result).rejects.toBeInstanceOf(PortNotConfiguredError);
    await expect(result).rejects.toThrow(
      'PushSender is not configured: set PUSH_ADAPTER to fcm or fake',
    );
  });
});

describe('createNoneFileStorage', () => {
  it('fails on every operation with a message naming STORAGE_ADAPTER', async () => {
    const storage = createNoneFileStorage();
    const message = 'FileStorage is not configured: set STORAGE_ADAPTER to firebase or fake';

    await expect(
      storage.save('a.txt', Buffer.from('x'), { contentType: 'text/plain' }),
    ).rejects.toThrow(message);
    await expect(storage.read('a.txt')).rejects.toThrow(message);
    await expect(storage.delete('a.txt')).rejects.toThrow(message);
    await expect(storage.read('a.txt')).rejects.toBeInstanceOf(PortNotConfiguredError);
  });
});
