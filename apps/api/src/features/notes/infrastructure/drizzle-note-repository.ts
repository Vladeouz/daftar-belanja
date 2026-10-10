import { and, desc, eq, sql } from 'drizzle-orm';
import { buildPage } from '../../../core/http/pagination.js';
import type { Database } from '../../../db/client.js';
import { notes } from '../../../db/schema/index.js';
import type { Note, NoteRepository } from '../domain/note.js';

type NoteRow = typeof notes.$inferSelect;

function toNote(row: NoteRow): Note {
  return {
    id: row.id,
    userId: row.userId,
    title: row.title,
    body: row.body,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

export function createDrizzleNoteRepository(db: Database): NoteRepository {
  const owned = (userId: string, id: string) => and(eq(notes.id, id), eq(notes.userId, userId));

  return {
    async create(input) {
      const [row] = await db.insert(notes).values(input).returning();
      if (!row) throw new Error('insert notes tidak mengembalikan baris');
      return toNote(row);
    },

    async listByUser(userId, { limit, cursor }) {
      // Ambil `limit + 1` baris; baris tambahan hanya menandakan ada halaman berikutnya.
      const rows = await db
        .select()
        .from(notes)
        .where(
          and(
            eq(notes.userId, userId),
            cursor
              ? sql`(${notes.createdAt}, ${notes.id}) < (${cursor.createdAt}::timestamptz, ${cursor.id}::uuid)`
              : undefined,
          ),
        )
        .orderBy(desc(notes.createdAt), desc(notes.id))
        .limit(limit + 1);

      // `created_at` berpresisi milidetik (`timestamptz(3)`), jadi `Date` dari baris persis sama
      // dengan nilai di database dan cukup untuk cursor.
      return buildPage(rows.map(toNote), limit, (note) => note);
    },

    async findById(userId, id) {
      const [row] = await db.select().from(notes).where(owned(userId, id));
      return row ? toNote(row) : null;
    },

    async update(userId, id, changes) {
      // `updated_at` diisi `$onUpdate` Drizzle.
      const [row] = await db
        .update(notes)
        .set({ title: changes.title, body: changes.body })
        .where(owned(userId, id))
        .returning();
      return row ? toNote(row) : null;
    },

    async delete(userId, id) {
      const rows = await db.delete(notes).where(owned(userId, id)).returning({ id: notes.id });
      return rows.length > 0;
    },
  };
}
