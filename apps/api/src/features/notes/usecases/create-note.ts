import type { Note, NoteRepository } from '../domain/note.js';

export interface CreateNoteInput {
  userId: string;
  title: string;
  body?: string;
}

export function createNote({ notes }: { notes: NoteRepository }) {
  return (input: CreateNoteInput): Promise<Note> =>
    notes.create({ userId: input.userId, title: input.title, body: input.body ?? '' });
}

export type CreateNote = ReturnType<typeof createNote>;
