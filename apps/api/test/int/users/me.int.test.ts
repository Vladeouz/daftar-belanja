import { eq } from 'drizzle-orm';
import { describe, expect, it } from 'vitest';
import type { ErrorBody } from '../../../src/core/http/errors.js';
import { users } from '../../../src/db/schema/index.js';
import type { UserDto } from '../../../src/features/users/http/me.route.js';
import { useTestDb } from '../../helpers/db.js';
import {
  createEmulatorTokenVerifier,
  signUp,
  unsignedIdToken,
  updateAccount,
} from '../../helpers/emulator-token.js';
import { createTestApp } from '../../helpers/test-app.js';

const getDb = useTestDb();
const tokenVerifier = createEmulatorTokenVerifier();

const app = () => createTestApp({ db: getDb().db, tokenVerifier });

const getMe = (token?: string) =>
  app().request('/v1/me', token ? { headers: { Authorization: `Bearer ${token}` } } : {});

const json = async <T = UserDto>(res: Response) => (await res.json()) as T;

const userRows = () => getDb().db.select().from(users);

const ISO_UTC = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;

describe('GET /v1/me tanpa token yang valid', () => {
  it('401 UNAUTHENTICATED tanpa header Authorization', async () => {
    const res = await getMe();

    expect(res.status).toBe(401);
    expect(await res.json()).toEqual({
      error: { code: 'UNAUTHENTICATED', message: 'Missing bearer token' },
    });
  });

  it('401 bila skema header bukan Bearer', async () => {
    const { idToken } = await signUp();
    const res = await app().request('/v1/me', { headers: { Authorization: `Basic ${idToken}` } });

    expect(res.status).toBe(401);
    expect(await userRows()).toHaveLength(0);
  });

  it.each([
    ['token rusak', () => 'bukan-jwt'],
    [
      'token kedaluwarsa',
      () => {
        const past = Math.floor(Date.now() / 1000) - 7200;
        return unsignedIdToken({ iat: past, auth_time: past, exp: past + 3600 });
      },
    ],
    ['token untuk project lain', () => unsignedIdToken({ aud: 'demo-lain' })],
  ])('401 dan tidak ada baris users baru: %s', async (_name, makeToken) => {
    const res = await getMe(makeToken());

    expect(res.status).toBe(401);
    expect((await json<ErrorBody>(res)).error).toEqual({
      code: 'UNAUTHENTICATED',
      message: 'Invalid or expired token',
    });
    expect(await userRows()).toHaveLength(0);
  });
});

describe('GET /v1/me dengan token dari Auth Emulator', () => {
  it('request pertama membuat satu baris users dan mengembalikan 200 User', async () => {
    const account = await signUp({ displayName: 'Budi' });

    const res = await getMe(account.idToken);

    expect(res.status).toBe(200);
    const body = await json(res);
    const rows = await userRows();
    expect(rows).toHaveLength(1);
    const [row] = rows;
    expect(row).toMatchObject({
      firebaseUid: account.uid,
      email: account.email,
      displayName: 'Budi',
    });
    expect(body).toEqual({
      id: row?.id,
      email: account.email,
      displayName: 'Budi',
      createdAt: row?.createdAt.toISOString(),
    });
    expect(body.createdAt).toMatch(ISO_UTC);
  });

  it('request berikutnya memakai baris yang sama', async () => {
    const { idToken } = await signUp();

    const first = await json(await getMe(idToken));
    const second = await json(await getMe(idToken));

    expect(second.id).toBe(first.id);
    expect(await userRows()).toHaveLength(1);
  });

  it('dua request pertama paralel dengan token yang sama tetap menghasilkan satu baris', async () => {
    const { uid, idToken } = await signUp();

    const responses = await Promise.all([getMe(idToken), getMe(idToken)]);

    expect(responses.map((r) => r.status)).toEqual([200, 200]);
    const [a, b] = await Promise.all(responses.map((r) => json(r)));
    expect(a?.id).toBe(b?.id);
    const rows = await getDb().db.select().from(users).where(eq(users.firebaseUid, uid));
    expect(rows).toHaveLength(1);
  });

  it('memperbarui email dan last_seen_at bila email di token berubah', async () => {
    const account = await signUp();
    await getMe(account.idToken);
    const [before] = await userRows();

    const newEmail = `Ganti-${account.uid}@Example.test`;
    const updated = await updateAccount(account, { email: newEmail });
    const res = await getMe(updated.idToken);

    expect(res.status).toBe(200);
    expect((await json(res)).email).toBe(newEmail.toLowerCase());
    const rows = await userRows();
    expect(rows).toHaveLength(1);
    const [after] = rows;
    expect(after?.id).toBe(before?.id);
    expect(after?.email).toBe(newEmail.toLowerCase());
    expect(after?.lastSeenAt.getTime()).toBeGreaterThan(before?.lastSeenAt.getTime() ?? 0);
    expect(after?.updatedAt.getTime()).toBeGreaterThan(before?.updatedAt.getTime() ?? 0);
    expect(after?.createdAt).toEqual(before?.createdAt);
  });
});
