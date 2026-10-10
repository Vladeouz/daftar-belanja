import { sql } from 'drizzle-orm';
import type { Database } from '../../../db/client.js';
import { users } from '../../../db/schema/index.js';
import type { User, UserRepository } from '../domain/user.js';

type UserRow = typeof users.$inferSelect;

function toUser(row: UserRow): User {
  return {
    id: row.id,
    firebaseUid: row.firebaseUid,
    email: row.email,
    displayName: row.displayName,
    lastSeenAt: row.lastSeenAt,
    createdAt: row.createdAt,
  };
}

export function createDrizzleUserRepository(db: Database): UserRepository {
  return {
    async upsertByFirebaseUid(input) {
      // ON CONFLICT membuat dua request pertama yang paralel tetap menghasilkan satu baris.
      const [row] = await db
        .insert(users)
        .values({
          firebaseUid: input.firebaseUid,
          email: input.email,
          displayName: input.displayName,
          lastSeenAt: input.seenAt,
        })
        .onConflictDoUpdate({
          target: users.firebaseUid,
          set: {
            email: sql`excluded.email`,
            displayName: sql`excluded.display_name`,
            lastSeenAt: sql`excluded.last_seen_at`,
            updatedAt: sql`now()`,
          },
        })
        .returning();
      if (!row) throw new Error('upsert users tidak mengembalikan baris');
      return toUser(row);
    },
  };
}
