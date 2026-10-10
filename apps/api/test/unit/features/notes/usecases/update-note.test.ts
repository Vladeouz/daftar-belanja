import { describe, expect, it } from 'vitest';
import { updateNote } from '../../../../../src/features/notes/usecases/update-note.js';
import { fakeNoteRepository } from '../fake-note-repository.js';

const T1 = new Date('2026-10-01T08:00:00.000Z');
const T2 = new Date('2026-10-01T09:00:00.000Z');

async function seed() {
  let at = T1;
  const fake = fakeNoteRepository({ now: () => at });
  const note = await fake.repo.create({ userId: 'user-a', title: 'Lama', body: 'Isi lama' });
  at = T2;
  return { ...fake, note };
}

describe('updateNote', () => {
  it('changes only the fields that are sent', async () => {
    const { repo, note } = await seed();

    const updated = await updateNote({ notes: repo })('user-a', note.id, { title: 'Baru' });

    expect(updated).toEqual({ ...note, title: 'Baru', updatedAt: T2 });
  });

  it('can set the body to an empty string', async () => {
    const { repo, note } = await seed();

    const updated = await updateNote({ notes: repo })('user-a', note.id, { body: '' });

    expect(updated).toMatchObject({ title: 'Lama', body: '' });
  });

  it('throws NOT_FOUND for a note of another user and leaves it unchanged', async () => {
    const { repo, rows, note } = await seed();

    await expect(
      updateNote({ notes: repo })('user-b', note.id, { title: 'Dibajak' }),
    ).rejects.toMatchObject({ code: 'NOT_FOUND', status: 404 });
    expect(rows.get(note.id)?.title).toBe('Lama');
  });
});
