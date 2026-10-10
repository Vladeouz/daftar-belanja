import type { FileStorage } from '../file-storage.js';
import type { PushSender } from '../push-sender.js';

// Dilempar oleh adapter `none` (default bila `PUSH_ADAPTER` atau `STORAGE_ADAPTER` tidak di-set).
// Sampai ke error handler sebagai `500 INTERNAL_ERROR`; pesan aslinya hanya ada di log.
export class PortNotConfiguredError extends Error {
  constructor(port: string, envKey: string, adapters: readonly string[]) {
    super(`${port} is not configured: set ${envKey} to ${adapters.join(' or ')}`);
    this.name = 'PortNotConfiguredError';
  }
}

// Adapter untuk proyek yang belum (atau tidak) memakai push. Server tetap bisa start; setiap
// pemakaian gagal dengan pesan yang menyebut env yang harus di-set.
export function createNonePushSender(): PushSender {
  return {
    async send() {
      throw new PortNotConfiguredError('PushSender', 'PUSH_ADAPTER', ['fcm', 'fake']);
    },
  };
}

export function createNoneFileStorage(): FileStorage {
  const fail = async (): Promise<never> => {
    throw new PortNotConfiguredError('FileStorage', 'STORAGE_ADAPTER', ['firebase', 'fake']);
  };
  return { save: fail, read: fail, delete: fail };
}
