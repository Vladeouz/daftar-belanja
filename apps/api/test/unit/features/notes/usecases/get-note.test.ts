import { describe, expect, it } from 'vitest';
import { AppError } from '../../../../../src/core/http/errors.js';
import { getNote } from '../../../../../src/features/notes/usecases/get-note.js';
import { fakeNoteRepository } from '../fake-note-repository.js';

const MISSING_ID = '00000000-0000-4000-8000-999999999999';

describe('getNote', () => {
  it('returns the note of its owner', async () => {
    const { repo } = fakeNoteRepository();
    const created = await repo.create({ userId: 'user-a', title: 'A', body: '' });

    expect(await getNote({ notes: repo })('user-a', created.id)).toEqual(created);
  });

  it('throws NOT_FOUND for a note of another user', async () => {
    const { repo } = fakeNoteRepository();
    const created = await repo.create({ userId: 'user-a', title: 'A', body: '' });

    const error = await getNote({ notes: repo })('user-b', created.id).catch((e: unknown) => e);

    expect(error).toBeInstanceOf(AppError);
    expect(error).toMatchObject({ code: 'NOT_FOUND', status: 404 });
  });

  it('throws NOT_FOUND for a note that does not exist', async () => {
    const { repo } = fakeNoteRepository();

    await expect(getNote({ notes: repo })('user-a', MISSING_ID)).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
  });
});
