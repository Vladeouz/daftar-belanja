import type { User, UserRepository } from '../domain/user.js';

export interface SyncUserInput {
  firebaseUid: string;
  email: string | null;
  displayName: string | null;
}

export interface SyncUserDeps {
  users: UserRepository;
  now?: () => Date;
}

// Dipanggil setelah ID token terverifikasi: memastikan baris `users` ada dan sesuai token.
// Email disimpan lowercase (CHECK `users_email_lowercase_check`); nama kosong dianggap tidak ada.
export function syncUser({ users, now = () => new Date() }: SyncUserDeps) {
  return (input: SyncUserInput): Promise<User> =>
    users.upsertByFirebaseUid({
      firebaseUid: input.firebaseUid,
      email: input.email?.trim().toLowerCase() || null,
      displayName: input.displayName?.trim() || null,
      seenAt: now(),
    });
}

export type SyncUser = ReturnType<typeof syncUser>;
