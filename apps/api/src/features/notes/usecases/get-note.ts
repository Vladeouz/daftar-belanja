import { AppError } from '../../../core/http/errors.js';
import type { Note, NoteRepository } from '../domain/note.js';

// Note milik user lain → `NOT_FOUND`, sama dengan note yang tidak ada (D-07).
export function getNote({ notes }: { notes: NoteRepository }) {
  return async (userId: string, id: string): Promise<Note> => {
    const note = await notes.findById(userId, id);
    if (!note) throw new AppError('NOT_FOUND', 'Note not found');
    return note;
  };
}

export type GetNote = ReturnType<typeof getNote>;
