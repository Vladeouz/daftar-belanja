import { describe, expect, it } from 'vitest';
import { decodeCursor } from '../../../../../src/core/http/pagination.js';
import { listNotes } from '../../../../../src/features/notes/usecases/list-notes.js';
import { fakeNoteRepository } from '../fake-note-repository.js';

// Note ke-i dibuat pada detik ke-i, jadi note terbaru adalah yang terakhir dibuat.
async function seed(count: number, userId = 'user-a') {
  let second = 0;
  const fake = fakeNoteRepository({ now: () => new Date(Date.UTC(2026, 9, 1, 8, 0, second++)) });
  for (let i = 1; i <= count; i++) {
    await fake.repo.create({ userId, title: `Note ${i}`, body: '' });
  }
  return fake;
}

describe('listNotes', () => {
  it('returns the newest notes first with a cursor to the next page', async () => {
    const { repo } = await seed(5);

    const page = await listNotes({ notes: repo })('user-a', { limit: 2 });

    expect(page.items.map((n) => n.title)).toEqual(['Note 5', 'Note 4']);
    expect(page.nextCursor).not.toBeNull();
    expect(decodeCursor(page.nextCursor ?? '')?.id).toBe(page.items[1]?.id);
  });

  it('continues after the cursor and ends with nextCursor null', async () => {
    const { repo } = await seed(3);
    const list = listNotes({ notes: repo });

    const first = await list('user-a', { limit: 2 });
    const cursor = decodeCursor(first.nextCursor ?? '') ?? undefined;
    const second = await list('user-a', { limit: 2, cursor });

    expect(second.items.map((n) => n.title)).toEqual(['Note 1']);
    expect(second.nextCursor).toBeNull();
  });

  it('only lists notes of the given user', async () => {
    const { repo } = await seed(2);
    await repo.create({ userId: 'user-b', title: 'Punya B', body: '' });

    const page = await listNotes({ notes: repo })('user-b', { limit: 20 });

    expect(page.items.map((n) => n.title)).toEqual(['Punya B']);
  });
});
