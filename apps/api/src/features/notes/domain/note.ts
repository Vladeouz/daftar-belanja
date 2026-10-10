import type { CursorPosition, Page } from '../../../core/http/pagination.js';

// CONTOH fitur: catatan milik satu user. Setiap akses selalu dibatasi `userId` pemiliknya;
// note milik user lain diperlakukan sama dengan note yang tidak ada (D-07).
export interface Note {
  id: string;
  userId: string;
  title: string;
  body: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface NewNote {
  userId: string;
  title: string;
  body: string;
}

// Minimal satu field terisi (dijaga skema route).
export interface NoteChanges {
  title?: string;
  body?: string;
}

export interface ListNotesQuery {
  limit: number;
  cursor?: CursorPosition;
}

export interface NoteRepository {
  create(input: NewNote): Promise<Note>;
  // Urutan `created_at DESC, id DESC`, mulai setelah `cursor`.
  listByUser(userId: string, query: ListNotesQuery): Promise<Page<Note>>;
  // `null` bila tidak ada atau bukan milik `userId`.
  findById(userId: string, id: string): Promise<Note | null>;
  update(userId: string, id: string, changes: NoteChanges): Promise<Note | null>;
  // `false` bila tidak ada atau bukan milik `userId`.
  delete(userId: string, id: string): Promise<boolean>;
}
