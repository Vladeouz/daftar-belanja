import { describe, expect, it } from 'vitest';
import type {
  UpsertUserInput,
  User,
  UserRepository,
} from '../../../../../src/features/users/domain/user.js';
import { syncUser } from '../../../../../src/features/users/usecases/sync-user.js';

// Repository palsu di memori dengan perilaku upsert yang sama dengan implementasi Drizzle.
function fakeUserRepository() {
  const rows = new Map<string, User>();
  const calls: UpsertUserInput[] = [];
  const repo: UserRepository = {
    async upsertByFirebaseUid(input) {
      calls.push(input);
      const existing = rows.get(input.firebaseUid);
      const user: User = {
        id: existing?.id ?? `id-${rows.size + 1}`,
        firebaseUid: input.firebaseUid,
        email: input.email,
        displayName: input.displayName,
        lastSeenAt: input.seenAt,
        createdAt: existing?.createdAt ?? input.seenAt,
      };
      rows.set(input.firebaseUid, user);
      return user;
    },
  };
  return { repo, rows, calls };
}

const T1 = new Date('2026-10-01T08:00:00.000Z');
const T2 = new Date('2026-10-01T09:00:00.000Z');

describe('syncUser', () => {
  it('creates the user on first call with seenAt from the clock', async () => {
    const { repo, calls } = fakeUserRepository();

    const user = await syncUser({ users: repo, now: () => T1 })({
      firebaseUid: 'uid-1',
      email: 'a@example.com',
      displayName: 'Ani',
    });

    expect(calls).toEqual([
      { firebaseUid: 'uid-1', email: 'a@example.com', displayName: 'Ani', seenAt: T1 },
    ]);
    expect(user).toMatchObject({ id: 'id-1', email: 'a@example.com', createdAt: T1 });
  });

  it('lowercases and trims the email', async () => {
    const { repo, calls } = fakeUserRepository();

    await syncUser({ users: repo, now: () => T1 })({
      firebaseUid: 'uid-1',
      email: '  Ani@Example.COM ',
      displayName: null,
    });

    expect(calls[0]?.email).toBe('ani@example.com');
  });

  it('stores empty email and display name as null', async () => {
    const { repo, calls } = fakeUserRepository();

    await syncUser({ users: repo, now: () => T1 })({
      firebaseUid: 'uid-1',
      email: ' ',
      displayName: '',
    });

    expect(calls[0]).toMatchObject({ email: null, displayName: null });
  });

  it('updates email and lastSeenAt for an existing user, keeping id and createdAt', async () => {
    const { repo } = fakeUserRepository();
    const first = await syncUser({ users: repo, now: () => T1 })({
      firebaseUid: 'uid-1',
      email: 'old@example.com',
      displayName: null,
    });

    const second = await syncUser({ users: repo, now: () => T2 })({
      firebaseUid: 'uid-1',
      email: 'new@example.com',
      displayName: null,
    });

    expect(second).toEqual({ ...first, email: 'new@example.com', lastSeenAt: T2 });
  });

  it('defaults the clock to the current time', async () => {
    const { repo, calls } = fakeUserRepository();
    const before = Date.now();

    await syncUser({ users: repo })({ firebaseUid: 'uid-1', email: null, displayName: null });

    expect(calls[0]?.seenAt.getTime()).toBeGreaterThanOrEqual(before);
  });
});
