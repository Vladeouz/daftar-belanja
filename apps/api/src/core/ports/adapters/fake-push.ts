import type { PushMessage, PushResult, PushSender } from '../push-sender.js';

// Adapter palsu untuk development dan test: tidak mengirim apa pun, hanya mencatat pesan agar
// bisa diperiksa test.
export interface FakePushSender extends PushSender {
  // Pesan yang berhasil "dikirim", berurutan.
  readonly sent: readonly PushMessage[];
  // Token yang ditandai tidak valid menghasilkan `invalid-token` dan tidak dicatat di `sent`.
  markInvalid(token: string): void;
  clear(): void;
}

export function createFakePushSender(): FakePushSender {
  const sent: PushMessage[] = [];
  const invalidTokens = new Set<string>();

  return {
    sent,
    markInvalid(token) {
      invalidTokens.add(token);
    },
    clear() {
      sent.length = 0;
      invalidTokens.clear();
    },
    async send(message): Promise<PushResult> {
      if (invalidTokens.has(message.token)) return { status: 'invalid-token' };
      sent.push(structuredClone(message));
      return { status: 'sent', messageId: `fake-${sent.length}` };
    },
  };
}
