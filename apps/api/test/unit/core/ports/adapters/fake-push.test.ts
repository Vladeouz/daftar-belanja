import { describe, expect, it } from 'vitest';
import { createFakePushSender } from '../../../../../src/core/ports/adapters/fake-push.js';

const message = { token: 'device-1', title: 'Halo', body: 'Isi', data: { noteId: 'n-1' } };

describe('createFakePushSender', () => {
  it('records sent messages in order and returns a message id', async () => {
    const push = createFakePushSender();

    await expect(push.send(message)).resolves.toEqual({ status: 'sent', messageId: 'fake-1' });
    await expect(push.send({ ...message, token: 'device-2' })).resolves.toEqual({
      status: 'sent',
      messageId: 'fake-2',
    });

    expect(push.sent).toEqual([message, { ...message, token: 'device-2' }]);
  });

  it('stores a copy, so later changes by the caller do not alter the record', async () => {
    const push = createFakePushSender();
    const data = { noteId: 'n-1' };

    await push.send({ ...message, data });
    data.noteId = 'changed';

    expect(push.sent[0]?.data).toEqual({ noteId: 'n-1' });
  });

  it('returns invalid-token for tokens marked invalid without recording them', async () => {
    const push = createFakePushSender();
    push.markInvalid('device-1');

    await expect(push.send(message)).resolves.toEqual({ status: 'invalid-token' });
    expect(push.sent).toEqual([]);
  });

  it('clears recorded messages and invalid tokens', async () => {
    const push = createFakePushSender();
    push.markInvalid('device-2');
    await push.send(message);

    push.clear();

    expect(push.sent).toEqual([]);
    await expect(push.send({ ...message, token: 'device-2' })).resolves.toMatchObject({
      status: 'sent',
    });
  });
});
