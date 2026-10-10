import { randomUUID } from 'node:crypto';
import { afterAll } from 'vitest';
import {
  createFirebaseAdmin,
  createFirebaseTokenVerifier,
  type TokenVerifier,
} from '../../src/core/auth/firebase-admin.js';

// Helper Auth Emulator (docker compose, port 9099) untuk integration test. Akun dibuat dengan
// email acak, jadi tidak perlu membersihkan emulator dan akun buatan manual tidak tersentuh.

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? 'demo-template';
const EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? 'localhost:9099';
const IDENTITY_TOOLKIT = `http://${EMULATOR_HOST}/identitytoolkit.googleapis.com/v1`;

export interface EmulatorUser {
  uid: string;
  email: string;
  idToken: string;
}

async function call<T>(method: string, body: Record<string, unknown>): Promise<T> {
  let res: Response;
  try {
    // Emulator menerima API key apa pun.
    res = await fetch(`${IDENTITY_TOOLKIT}/accounts:${method}?key=fake-api-key`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    });
  } catch (err) {
    throw new Error(
      `Tidak bisa terhubung ke Auth Emulator (${EMULATOR_HOST}). Pastikan Docker Desktop berjalan, lalu docker compose up -d --wait.`,
      { cause: err },
    );
  }
  if (!res.ok) {
    throw new Error(`Auth Emulator accounts:${method} → ${res.status}: ${await res.text()}`);
  }
  return (await res.json()) as T;
}

export function randomEmail(): string {
  return `user-${randomUUID()}@example.test`;
}

const PASSWORD = 'password-123';

type AccountResponse = { localId: string; email: string; idToken?: string };

// Mendaftarkan akun baru dan mengembalikan ID token-nya.
export async function signUp(
  options: { email?: string; displayName?: string } = {},
): Promise<EmulatorUser> {
  const signedUp = await call<AccountResponse>('signUp', {
    email: options.email ?? randomEmail(),
    password: PASSWORD,
    displayName: options.displayName,
    returnSecureToken: true,
  });
  return withToken(signedUp);
}

// Mengubah email atau nama akun dan mengembalikan ID token baru yang berisi klaim terbaru.
export async function updateAccount(
  user: { idToken: string },
  changes: { email?: string; displayName?: string },
): Promise<EmulatorUser> {
  const updated = await call<AccountResponse>('update', {
    idToken: user.idToken,
    ...changes,
    returnSecureToken: true,
  });
  return withToken(updated);
}

// Emulator hanya menerbitkan token baru untuk perubahan tertentu (misalnya email, bukan
// displayName); bila tidak ada, login ulang dengan password.
async function withToken(account: AccountResponse): Promise<EmulatorUser> {
  const idToken =
    account.idToken ??
    (
      await call<AccountResponse>('signInWithPassword', {
        email: account.email,
        password: PASSWORD,
        returnSecureToken: true,
      })
    ).idToken;
  if (!idToken) throw new Error('Auth Emulator tidak mengembalikan idToken');
  return { uid: account.localId, email: account.email, idToken };
}

function base64url(value: object): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

// ID token tanpa tanda tangan (format yang diterbitkan emulator) dengan klaim yang bisa diatur,
// misalnya `exp` di masa lalu untuk token kedaluwarsa atau `aud` project lain.
export function unsignedIdToken(claims: Record<string, unknown> = {}): string {
  const now = Math.floor(Date.now() / 1000);
  const uid = randomUUID();
  const payload = {
    iss: `https://securetoken.google.com/${PROJECT_ID}`,
    aud: PROJECT_ID,
    auth_time: now,
    user_id: uid,
    sub: uid,
    iat: now,
    exp: now + 3600,
    ...claims,
  };
  return `${base64url({ alg: 'none', typ: 'JWT' })}.${base64url(payload)}.`;
}

// Verifier sungguhan (firebase-admin ke Auth Emulator). App firebase-admin dihapus setelah file
// test selesai.
export function createEmulatorTokenVerifier(): TokenVerifier {
  const firebase = createFirebaseAdmin(PROJECT_ID);
  afterAll(() => firebase.close());
  return createFirebaseTokenVerifier(firebase.auth);
}
