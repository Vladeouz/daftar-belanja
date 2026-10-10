import type { Page } from '../../../core/http/pagination.js';
import type { ListNotesQuery, Note, NoteRepository } from '../domain/note.js';

export function listNotes({ notes }: { notes: NoteRepository }) {
  return (userId: string, query: ListNotesQuery): Promise<Page<Note>> =>
    notes.listByUser(userId, query);
}

export type ListNotes = ReturnType<typeof listNotes>;
