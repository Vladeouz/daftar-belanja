import type { App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { getStorage } from 'firebase-admin/storage';
import type { Env } from '../config/env.js';
import { createFakePushSender } from './adapters/fake-push.js';
import { createFakeFileStorage } from './adapters/fake-storage.js';
import { createFcmPushSender } from './adapters/fcm-push.js';
import { createFirebaseFileStorage } from './adapters/firebase-storage.js';
import { createNoneFileStorage, createNonePushSender } from './adapters/none.js';
import type { FileStorage } from './file-storage.js';
import type { PushSender } from './push-sender.js';

export interface Ports {
  pushSender: PushSender;
  fileStorage: FileStorage;
}

export type PortsEnv = Pick<Env, 'PUSH_ADAPTER' | 'STORAGE_ADAPTER' | 'FIREBASE_STORAGE_BUCKET'>;

// Memilih adapter dari env. Klien firebase-admin hanya dibuat untuk adapter yang memakainya.
export function createPorts(env: PortsEnv, firebaseApp: App): Ports {
  return {
    pushSender: createPushSender(env, firebaseApp),
    fileStorage: createFileStorage(env, firebaseApp),
  };
}

function createPushSender(env: PortsEnv, firebaseApp: App): PushSender {
  switch (env.PUSH_ADAPTER) {
    case 'fcm':
      return createFcmPushSender(getMessaging(firebaseApp));
    case 'fake':
      return createFakePushSender();
    case 'none':
      return createNonePushSender();
  }
}

function createFileStorage(env: PortsEnv, firebaseApp: App): FileStorage {
  switch (env.STORAGE_ADAPTER) {
    case 'firebase':
      return createFirebaseFileStorage(getStorage(firebaseApp).bucket(requireBucket(env)));
    case 'fake':
      return createFakeFileStorage();
    case 'none':
      return createNoneFileStorage();
  }
}

// `loadEnv()` sudah mewajibkannya untuk adapter `firebase`; dicek ulang untuk env buatan tangan.
function requireBucket(env: PortsEnv): string {
  if (!env.FIREBASE_STORAGE_BUCKET) {
    throw new Error('FIREBASE_STORAGE_BUCKET is required when STORAGE_ADAPTER=firebase');
  }
  return env.FIREBASE_STORAGE_BUCKET;
}
