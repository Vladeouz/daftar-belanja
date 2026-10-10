import { randomUUID } from 'node:crypto';
import { type App, deleteApp, initializeApp } from 'firebase-admin/app';
import { type Auth, FirebaseAuthError, getAuth } from 'firebase-admin/auth';

// Identitas dari ID token yang sudah diverifikasi.
export interface VerifiedIdentity {
  firebaseUid: string;
  email: string | null;
  displayName: string | null;
}

// Port verifikasi token; middleware `authenticate` hanya bergantung pada interface ini.
export interface TokenVerifier {
  // `null` bila token tidak valid, kedaluwarsa, atau bukan untuk project ini.
  // Error lain (misalnya sertifikat Google tidak bisa diambil) dilempar ulang.
  verify(idToken: string): Promise<VerifiedIdentity | null>;
}

export interface FirebaseAdmin {
  app: App;
  auth: Auth;
  close(): Promise<void>;
}

// Hanya `projectId` yang dibutuhkan untuk `verifyIdToken`: tanpa service account, baik di Auth
// Emulator (`FIREBASE_AUTH_EMULATOR_HOST`, dibaca firebase-admin dari process.env) maupun produksi.
// Nama app unik agar beberapa instance (misalnya di test) tidak bentrok dengan app default.
export function createFirebaseAdmin(projectId: string): FirebaseAdmin {
  const app = initializeApp({ projectId }, `api-${randomUUID()}`);
  return { app, auth: getAuth(app), close: () => deleteApp(app) };
}

// `auth/internal-error` berarti verifikasi tidak bisa dijalankan, bukan token yang salah.
const UNVERIFIABLE = 'auth/internal-error';

export function createFirebaseTokenVerifier(auth: Pick<Auth, 'verifyIdToken'>): TokenVerifier {
  return {
    async verify(idToken) {
      try {
        const decoded = await auth.verifyIdToken(idToken);
        return {
          firebaseUid: decoded.uid,
          email: decoded.email ?? null,
          displayName: typeof decoded.name === 'string' ? decoded.name : null,
        };
      } catch (err) {
        if (err instanceof FirebaseAuthError && err.code !== UNVERIFIABLE) return null;
        throw err;
      }
    },
  };
}
