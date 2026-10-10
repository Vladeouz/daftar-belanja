import { buildPage } from '../../../../src/core/http/pagination.js';
import {
  type ShoppingItem,
  ShoppingItemNameTakenError,
  type ShoppingItemRepository,
} from '../../../../src/features/shopping/domain/shopping-item.js';

// Repository palsu di memori dengan perilaku yang sama dengan implementasi Drizzle: akses dibatasi
// pemilik, nama unik per user tanpa membedakan huruf besar dan kecil, filter status, urutan
// `createdAt DESC, id DESC`, dan cursor.
export function fakeShoppingItemRepository(options: { now?: () => Date } = {}) {
  const now = options.now ?? (() => new Date());
  const rows = new Map<string, ShoppingItem>();
  let seq = 0;

  const owned = (userId: string, id: string) => {
    const item = rows.get(id);
    return item && item.userId === userId ? item : null;
  };

  const assertNameFree = (userId: string, name: string, exceptId?: string) => {
    const taken = [...rows.values()].some(
      (i) =>
        i.userId === userId && i.id !== exceptId && i.name.toLowerCase() === name.toLowerCase(),
    );
    if (taken) throw new ShoppingItemNameTakenError();
  };

  const repo: ShoppingItemRepository = {
    async create(input) {
      assertNameFree(input.userId, input.name);
      seq += 1;
      const at = now();
      const item: ShoppingItem = {
        id: `00000000-0000-4000-8000-${String(seq).padStart(12, '0')}`,
        ...input,
        isDone: false,
        createdAt: at,
        updatedAt: at,
      };
      rows.set(item.id, item);
      return { ...item };
    },

    async listByUser(userId, { limit, cursor, status }) {
      const sorted = [...rows.values()]
        .filter((i) => i.userId === userId)
        .filter((i) => status === 'all' || i.isDone === (status === 'done'))
        .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime() || (a.id < b.id ? 1 : -1))
        .filter((i) => {
          if (!cursor) return true;
          const at = new Date(cursor.createdAt).getTime();
          const t = i.createdAt.getTime();
          return t < at || (t === at && i.id < cursor.id);
        });
      return buildPage(sorted.slice(0, limit + 1), limit, (i) => i);
    },

    async update(userId, id, changes) {
      const item = owned(userId, id);
      if (!item) return null;
      if (changes.name !== undefined) assertNameFree(userId, changes.name, id);
      const updated: ShoppingItem = {
        ...item,
        name: changes.name ?? item.name,
        quantity: changes.quantity ?? item.quantity,
        isDone: changes.isDone ?? item.isDone,
        updatedAt: now(),
      };
      rows.set(id, updated);
      return { ...updated };
    },

    async delete(userId, id) {
      if (!owned(userId, id)) return false;
      return rows.delete(id);
    },

    async deleteDone(userId) {
      const done = [...rows.values()].filter((i) => i.userId === userId && i.isDone);
      for (const item of done) rows.delete(item.id);
      return done.length;
    },
  };

  return { repo, rows };
}
