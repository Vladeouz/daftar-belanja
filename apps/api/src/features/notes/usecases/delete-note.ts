import { AppError } from '../../../core/http/errors.js';
import type { NoteRepository } from '../domain/note.js';

// Note milik user lain → `NOT_FOUND` (D-07).
export function deleteNote({ notes }: { notes: NoteRepository }) {
  return async (userId: string, id: string): Promise<void> => {
    const deleted = await notes.delete(userId, id);
    if (!deleted) throw new AppError('NOT_FOUND', 'Note not found');
  };
}

export type DeleteNote = ReturnType<typeof deleteNote>;
