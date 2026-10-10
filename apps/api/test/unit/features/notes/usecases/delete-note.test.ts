import { describe, expect, it } from 'vitest';
import { deleteNote } from '../../../../../src/features/notes/usecases/delete-note.js';
import { fakeNoteRepository } from '../fake-note-repository.js';

describe('deleteNote', () => {
  it('deletes the note of its owner', async () => {
    const { repo, rows } = fakeNoteRepository();
    const note = await repo.create({ userId: 'user-a', title: 'A', body: '' });

    await deleteNote({ notes: repo })('user-a', note.id);

    expect(rows.has(note.id)).toBe(false);
  });

  it('throws NOT_FOUND for a note of another user and keeps it', async () => {
    const { repo, rows } = fakeNoteRepository();
    const note = await repo.create({ userId: 'user-a', title: 'A', body: '' });

    await expect(deleteNote({ notes: repo })('user-b', note.id)).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
    expect(rows.has(note.id)).toBe(true);
  });

  it('throws NOT_FOUND when deleting twice', async () => {
    const { repo } = fakeNoteRepository();
    const note = await repo.create({ userId: 'user-a', title: 'A', body: '' });
    const remove = deleteNote({ notes: repo });

    await remove('user-a', note.id);

    await expect(remove('user-a', note.id)).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });
});
