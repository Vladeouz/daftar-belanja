import { FirebaseMessagingError, type Messaging } from 'firebase-admin/messaging';
import type { PushSender } from '../push-sender.js';

// Kode FCM yang berarti token perangkat tidak bisa dipakai lagi.
const INVALID_TOKEN_CODES = ['registration-token-not-registered', 'invalid-registration-token'];

// Adapter Firebase Cloud Messaging lewat firebase-admin. Tidak ada emulator FCM, jadi adapter ini
// hanya diuji dengan `messaging` palsu. Di produksi butuh kredensial (Application Default
// Credentials), bukan sekadar `projectId`.
export function createFcmPushSender(messaging: Pick<Messaging, 'send'>): PushSender {
  return {
    async send({ token, title, body, data }) {
      try {
        const messageId = await messaging.send({
          token,
          notification: { title, body },
          ...(data ? { data } : {}),
        });
        return { status: 'sent', messageId };
      } catch (err) {
        if (
          err instanceof FirebaseMessagingError &&
          INVALID_TOKEN_CODES.some((code) => err.hasCode(code))
        ) {
          return { status: 'invalid-token' };
        }
        throw err;
      }
    },
  };
}
