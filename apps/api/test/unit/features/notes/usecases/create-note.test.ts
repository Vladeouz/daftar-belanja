import { describe, expect, it } from 'vitest';
import { createNote } from '../../../../../src/features/notes/usecases/create-note.js';
import { fakeNoteRepository } from '../fake-note-repository.js';

const T1 = new Date('2026-10-01T08:00:00.000Z');

describe('createNote', () => {
  it('creates a note owned by the user', async () => {
    const { repo, rows } = fakeNoteRepository({ now: () => T1 });

    const note = await createNote({ notes: repo })({
      userId: 'user-a',
      title: 'Belanja',
      body: 'Beras',
    });

    expect(note).toMatchObject({
      userId: 'user-a',
      title: 'Belanja',
      body: 'Beras',
      createdAt: T1,
      updatedAt: T1,
    });
    expect(rows.get(note.id)).toEqual(note);
  });

  it('defaults body to an empty string', async () => {
    const { repo } = fakeNoteRepository();

    const note = await createNote({ notes: repo })({ userId: 'user-a', title: 'Tanpa isi' });

    expect(note.body).toBe('');
  });
});
