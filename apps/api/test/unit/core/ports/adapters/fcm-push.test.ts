import { FirebaseMessagingError, type Message } from 'firebase-admin/messaging';
import { describe, expect, it, vi } from 'vitest';
import { createFcmPushSender } from '../../../../../src/core/ports/adapters/fcm-push.js';

// Tidak ada emulator FCM: `messaging.send` firebase-admin diganti mock.
function fcmWith(send: (message: Message) => Promise<string>) {
  const messaging = { send: vi.fn(send) };
  return { messaging, push: createFcmPushSender(messaging) };
}

function messagingError(code: string): FirebaseMessagingError {
  return new FirebaseMessagingError({ code, message: code });
}

describe('createFcmPushSender', () => {
  it('sends a notification message to the device token', async () => {
    const { messaging, push } = fcmWith(async () => 'projects/demo/messages/1');

    const result = await push.send({
      token: 'device-1',
      title: 'Halo',
      body: 'Isi',
      data: { noteId: 'n-1' },
    });

    expect(result).toEqual({ status: 'sent', messageId: 'projects/demo/messages/1' });
    expect(messaging.send).toHaveBeenCalledOnce();
    expect(messaging.send).toHaveBeenCalledWith({
      token: 'device-1',
      notification: { title: 'Halo', body: 'Isi' },
      data: { noteId: 'n-1' },
    });
  });

  it('omits data when none is given', async () => {
    const { messaging, push } = fcmWith(async () => 'id');

    await push.send({ token: 'device-1', title: 'Halo', body: 'Isi' });

    expect(messaging.send).toHaveBeenCalledWith({
      token: 'device-1',
      notification: { title: 'Halo', body: 'Isi' },
    });
  });

  it.each(['registration-token-not-registered', 'invalid-registration-token'])(
    'returns invalid-token for messaging/%s',
    async (code) => {
      const { push } = fcmWith(async () => {
        throw messagingError(code);
      });

      await expect(push.send({ token: 'old', title: 't', body: 'b' })).resolves.toEqual({
        status: 'invalid-token',
      });
    },
  );

  it('rethrows other messaging errors', async () => {
    const error = messagingError('server-unavailable');
    const { push } = fcmWith(async () => {
      throw error;
    });

    await expect(push.send({ token: 'device-1', title: 't', body: 'b' })).rejects.toBe(error);
  });

  it('rethrows errors that are not FirebaseMessagingError', async () => {
    const error = Object.assign(new Error('boom'), { code: 'registration-token-not-registered' });
    const { push } = fcmWith(async () => {
      throw error;
    });

    await expect(push.send({ token: 'device-1', title: 't', body: 'b' })).rejects.toBe(error);
  });
});
