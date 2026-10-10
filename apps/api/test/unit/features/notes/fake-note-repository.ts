import { buildPage } from '../../../../src/core/http/pagination.js';
import type { Note, NoteRepository } from '../../../../src/features/notes/domain/note.js';

// Repository palsu di memori dengan perilaku yang sama dengan implementasi Drizzle: akses dibatasi
// pemilik, urutan `createdAt DESC, id DESC`, dan cursor.
export function fakeNoteRepository(options: { now?: () => Date } = {}) {
  const now = options.now ?? (() => new Date());
  const rows = new Map<string, Note>();
  let seq = 0;

  const owned = (userId: string, id: string) => {
    const note = rows.get(id);
    return note && note.userId === userId ? note : null;
  };

  const repo: NoteRepository = {
    async create(input) {
      seq += 1;
      const at = now();
      const note: Note = {
        id: `00000000-0000-4000-8000-${String(seq).padStart(12, '0')}`,
        ...input,
        createdAt: at,
        updatedAt: at,
      };
      rows.set(note.id, note);
      return { ...note };
    },

    async listByUser(userId, { limit, cursor }) {
      const sorted = [...rows.values()]
        .filter((n) => n.userId === userId)
        .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime() || (a.id < b.id ? 1 : -1))
        .filter((n) => {
          if (!cursor) return true;
          const at = new Date(cursor.createdAt).getTime();
          const t = n.createdAt.getTime();
          return t < at || (t === at && n.id < cursor.id);
        });
      return buildPage(sorted.slice(0, limit + 1), limit, (n) => n);
    },

    async findById(userId, id) {
      const note = owned(userId, id);
      return note ? { ...note } : null;
    },

    async update(userId, id, changes) {
      const note = owned(userId, id);
      if (!note) return null;
      const updated: Note = {
        ...note,
        title: changes.title ?? note.title,
        body: changes.body ?? note.body,
        updatedAt: now(),
      };
      rows.set(id, updated);
      return { ...updated };
    },

    async delete(userId, id) {
      if (!owned(userId, id)) return false;
      return rows.delete(id);
    },
  };

  return { repo, rows };
}
