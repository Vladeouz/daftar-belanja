import type { App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { getStorage } from 'firebase-admin/storage';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { PortNotConfiguredError } from '../../../../src/core/ports/adapters/none.js';
import { createPorts, type PortsEnv } from '../../../../src/core/ports/create-ports.js';

// firebase-admin di-mock: test ini hanya memeriksa adapter mana yang dipilih dari env dan bahwa
// adapter Firebase memakai klien firebase-admin dari app yang diberikan.
const { messaging, file, bucket, storage } = vi.hoisted(() => {
  const file = { save: vi.fn(async () => undefined) };
  const bucket = { file: vi.fn(() => file) };
  return {
    messaging: { send: vi.fn(async () => 'projects/demo/messages/1') },
    file,
    bucket,
    storage: { bucket: vi.fn(() => bucket) },
  };
});

vi.mock('firebase-admin/messaging', async (importOriginal) => ({
  ...(await importOriginal<typeof import('firebase-admin/messaging')>()),
  getMessaging: vi.fn(() => messaging),
}));
vi.mock('firebase-admin/storage', () => ({ getStorage: vi.fn(() => storage) }));

const app = { name: 'test-app' } as App;
const fakes: PortsEnv = { PUSH_ADAPTER: 'fake', STORAGE_ADAPTER: 'fake' };

beforeEach(() => {
  vi.clearAllMocks();
});

describe('createPorts', () => {
  it('uses the none adapters, which fail on use, without creating firebase-admin clients', async () => {
    const ports = createPorts({ PUSH_ADAPTER: 'none', STORAGE_ADAPTER: 'none' }, app);

    expect(getMessaging).not.toHaveBeenCalled();
    expect(getStorage).not.toHaveBeenCalled();
    await expect(
      ports.pushSender.send({ token: 'device-1', title: 't', body: 'b' }),
    ).rejects.toBeInstanceOf(PortNotConfiguredError);
    await expect(ports.fileStorage.read('a.txt')).rejects.toBeInstanceOf(PortNotConfiguredError);
  });

  it('uses the fake adapters without creating firebase-admin clients', async () => {
    const ports = createPorts(fakes, app);

    expect(getMessaging).not.toHaveBeenCalled();
    expect(getStorage).not.toHaveBeenCalled();
    expect(ports.pushSender).toHaveProperty('sent');
    expect(ports.fileStorage).toHaveProperty('paths');
  });

  it('uses FCM through firebase-admin messaging when PUSH_ADAPTER=fcm', async () => {
    const { pushSender } = createPorts({ ...fakes, PUSH_ADAPTER: 'fcm' }, app);

    const result = await pushSender.send({ token: 'device-1', title: 't', body: 'b' });

    expect(getMessaging).toHaveBeenCalledWith(app);
    expect(messaging.send).toHaveBeenCalledWith({
      token: 'device-1',
      notification: { title: 't', body: 'b' },
    });
    expect(result).toEqual({ status: 'sent', messageId: 'projects/demo/messages/1' });
    expect(getStorage).not.toHaveBeenCalled();
  });

  it('uses Firebase Storage with the configured bucket when STORAGE_ADAPTER=firebase', async () => {
    const { fileStorage } = createPorts(
      {
        ...fakes,
        STORAGE_ADAPTER: 'firebase',
        FIREBASE_STORAGE_BUCKET: 'demo-template.appspot.com',
      },
      app,
    );

    await fileStorage.save('a.txt', Buffer.from('x'), { contentType: 'text/plain' });

    expect(getStorage).toHaveBeenCalledWith(app);
    expect(storage.bucket).toHaveBeenCalledWith('demo-template.appspot.com');
    expect(bucket.file).toHaveBeenCalledWith('a.txt');
    expect(file.save).toHaveBeenCalledOnce();
    expect(getMessaging).not.toHaveBeenCalled();
  });

  it('throws when STORAGE_ADAPTER=firebase has no bucket', () => {
    expect(() => createPorts({ ...fakes, STORAGE_ADAPTER: 'firebase' }, app)).toThrow(
      /FIREBASE_STORAGE_BUCKET/,
    );
  });
});
