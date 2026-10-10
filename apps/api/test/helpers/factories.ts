import { randomUUID } from 'node:crypto';
import type { Database } from '../../src/db/client.js';
import { notes, users } from '../../src/db/schema/index.js';

// Membuat baris langsung di database test untuk menyiapkan data integration test. Data yang
// diuji lewat HTTP tetap dibuat lewat route; factory hanya untuk keadaan awal.

export type UserRow = typeof users.$inferSelect;
export type NoteRow = typeof notes.$inferSelect;

export async function insertUser(
  db: Database,
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<UserRow> {
  const [row] = await db
    .insert(users)
    .values({ firebaseUid: `uid-${randomUUID()}`, ...overrides })
    .returning();
  if (!row) throw new Error('insertUser: tidak ada baris');
  return row;
}

export async function insertNote(
  db: Database,
  values: Pick<typeof notes.$inferInsert, 'userId'> & Partial<typeof notes.$inferInsert>,
): Promise<NoteRow> {
  const [row] = await db
    .insert(notes)
    .values({ title: 'Note', ...values })
    .returning();
  if (!row) throw new Error('insertNote: tidak ada baris');
  return row;
}

// `count` note dengan `created_at` berbeda 1 detik (note ke-1 paling lama), agar urutan
// `created_at DESC` bisa ditebak.
export async function insertNotes(
  db: Database,
  userId: string,
  count: number,
  start = new Date('2026-10-01T08:00:00.000Z'),
): Promise<NoteRow[]> {
  const rows: NoteRow[] = [];
  for (let i = 0; i < count; i++) {
    rows.push(
      await insertNote(db, {
        userId,
        title: `Note ${i + 1}`,
        createdAt: new Date(start.getTime() + i * 1000),
      }),
    );
  }
  return rows;
}
