import { sql } from 'drizzle-orm';
import { check, pgTable, text } from 'drizzle-orm/pg-core';
import { createdAt, id, timestamptz, updatedAt } from './columns.js';

// Identitas dan password dikelola Firebase Auth; baris dibuat lewat upsert saat request pertama.
export const users = pgTable(
  'users',
  {
    id: id(),
    firebaseUid: text('firebase_uid').notNull().unique('users_firebase_uid_unique'),
    // Diambil dari ID token. Nullable karena tidak semua provider Firebase memberi email.
    email: text('email'),
    displayName: text('display_name'),
    lastSeenAt: timestamptz('last_seen_at').notNull().defaultNow(),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (table) => [check('users_email_lowercase_check', sql`${table.email} = lower(${table.email})`)],
);
