import { AppError } from '../../../core/http/errors.js';
import type { Note, NoteChanges, NoteRepository } from '../domain/note.js';

// Hanya field yang dikirim yang diubah. Note milik user lain → `NOT_FOUND` (D-07).
export function updateNote({ notes }: { notes: NoteRepository }) {
  return async (userId: string, id: string, changes: NoteChanges): Promise<Note> => {
    const note = await notes.update(userId, id, changes);
    if (!note) throw new AppError('NOT_FOUND', 'Note not found');
    return note;
  };
}

export type UpdateNote = ReturnType<typeof updateNote>;
