import type { DecodedIdToken } from 'firebase-admin/auth';
import { FirebaseAuthError } from 'firebase-admin/auth';
import { describe, expect, it, vi } from 'vitest';
import {
  createFirebaseAdmin,
  createFirebaseTokenVerifier,
} from '../../../../src/core/auth/firebase-admin.js';

// FirebaseAuthError tidak punya constructor publik di tipe; dibuat lewat prototype agar
// `instanceof` tetap berlaku.
function authError(code: string): FirebaseAuthError {
  return Object.assign(Object.create(FirebaseAuthError.prototype) as FirebaseAuthError, {
    code,
    message: code,
  });
}

function verifierWith(verifyIdToken: (token: string) => Promise<DecodedIdToken>) {
  return createFirebaseTokenVerifier({ verifyIdToken: vi.fn(verifyIdToken) });
}

describe('createFirebaseTokenVerifier', () => {
  it('maps the decoded token to an identity', async () => {
    const verifier = verifierWith(
      async () =>
        ({ uid: 'uid-1', email: 'a@example.com', name: 'Ani' }) as unknown as DecodedIdToken,
    );

    await expect(verifier.verify('token')).resolves.toEqual({
      firebaseUid: 'uid-1',
      email: 'a@example.com',
      displayName: 'Ani',
    });
  });

  it('uses null for missing email and name', async () => {
    const verifier = verifierWith(async () => ({ uid: 'uid-2' }) as unknown as DecodedIdToken);

    await expect(verifier.verify('token')).resolves.toEqual({
      firebaseUid: 'uid-2',
      email: null,
      displayName: null,
    });
  });

  it.each(['auth/argument-error', 'auth/id-token-expired', 'auth/invalid-id-token'])(
    'returns null for %s',
    async (code) => {
      const verifier = verifierWith(async () => {
        throw authError(code);
      });

      await expect(verifier.verify('token')).resolves.toBeNull();
    },
  );

  it('rethrows auth/internal-error (token could not be verified at all)', async () => {
    const error = authError('auth/internal-error');
    const verifier = verifierWith(async () => {
      throw error;
    });

    await expect(verifier.verify('token')).rejects.toBe(error);
  });

  it('rethrows errors that are not FirebaseAuthError', async () => {
    const error = new Error('network down');
    const verifier = verifierWith(async () => {
      throw error;
    });

    await expect(verifier.verify('token')).rejects.toBe(error);
  });
});

describe('createFirebaseAdmin', () => {
  it('creates independent apps for the same project and deletes them on close', async () => {
    const a = createFirebaseAdmin('demo-template');
    const b = createFirebaseAdmin('demo-template');

    expect(a.app.name).not.toBe(b.app.name);
    expect(a.app.options.projectId).toBe('demo-template');

    await a.close();
    await b.close();
  });
});
