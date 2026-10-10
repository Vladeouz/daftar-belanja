import { createRoute, type OpenAPIHono, z } from '@hono/zod-openapi';
import { bearerSecurity } from '../../../core/auth/authenticate.js';
import type { AppEnv } from '../../../core/http/context.js';
import { errorResponse } from '../../../core/http/errors.js';
import { PaginationQuerySchema, pageSchema } from '../../../core/http/pagination.js';
import type { Note } from '../domain/note.js';
import type { CreateNote } from '../usecases/create-note.js';
import type { DeleteNote } from '../usecases/delete-note.js';
import type { GetNote } from '../usecases/get-note.js';
import type { ListNotes } from '../usecases/list-notes.js';
import type { UpdateNote } from '../usecases/update-note.js';

// Batas sama dengan CHECK `notes_title_length_check` dan `notes_body_length_check`.
export const TITLE_MAX = 120;
export const BODY_MAX = 5000;

// Spasi di tepi dibuang sebelum cek panjang: judul berisi spasi saja → 422 `too_small`.
const Title = z.string().trim().min(1).max(TITLE_MAX).openapi({ example: 'Belanja mingguan' });
const Body = z.string().max(BODY_MAX).openapi({ example: 'Beras, telur, sayur' });

export const NoteSchema = z
  .object({
    id: z.uuid(),
    title: z.string(),
    body: z.string(),
    createdAt: z.iso.datetime().openapi({ example: '2026-10-01T08:30:00.000Z' }),
    updatedAt: z.iso.datetime().openapi({ example: '2026-10-01T08:30:00.000Z' }),
  })
  .openapi('Note');

export const NotePageSchema = pageSchema(NoteSchema, 'NotePage');

export const CreateNoteBodySchema = z
  .object({ title: Title, body: Body.optional() })
  .openapi('CreateNoteInput');

// Minimal satu field; body kosong `{}` → `details._root`.
export const UpdateNoteBodySchema = z
  .object({ title: Title.optional(), body: Body.optional() })
  .refine((value) => value.title !== undefined || value.body !== undefined, {
    message: 'At least one of title or body is required',
  })
  .openapi('UpdateNoteInput');

// `id` yang bukan UUID → 422 `details.id`.
const NoteParamsSchema = z.object({
  id: z.uuid().openapi({ param: { name: 'id', in: 'path' } }),
});

export type NoteDto = z.infer<typeof NoteSchema>;

export function toNoteDto(note: Note): NoteDto {
  return {
    id: note.id,
    title: note.title,
    body: note.body,
    createdAt: note.createdAt.toISOString(),
    updatedAt: note.updatedAt.toISOString(),
  };
}

const unauthenticated = errorResponse('Token tidak ada, tidak valid, atau kedaluwarsa');
const notFound = errorResponse('Note tidak ada atau milik user lain');
const invalid = errorResponse('Validasi gagal');

export const listNotesRoute = createRoute({
  method: 'get',
  path: '/v1/notes',
  operationId: 'listNotes',
  tags: ['notes'],
  summary: 'Daftar note milik user, terbaru lebih dulu',
  security: bearerSecurity,
  request: { query: PaginationQuerySchema },
  responses: {
    200: {
      description: 'Satu halaman note',
      content: { 'application/json': { schema: NotePageSchema } },
    },
    401: unauthenticated,
    422: invalid,
  },
});

export const createNoteRoute = createRoute({
  method: 'post',
  path: '/v1/notes',
  operationId: 'createNote',
  tags: ['notes'],
  summary: 'Buat note',
  security: bearerSecurity,
  request: {
    body: { required: true, content: { 'application/json': { schema: CreateNoteBodySchema } } },
  },
  responses: {
    201: { description: 'Note dibuat', content: { 'application/json': { schema: NoteSchema } } },
    401: unauthenticated,
    422: invalid,
  },
});

export const getNoteRoute = createRoute({
  method: 'get',
  path: '/v1/notes/{id}',
  operationId: 'getNote',
  tags: ['notes'],
  summary: 'Satu note milik user',
  security: bearerSecurity,
  request: { params: NoteParamsSchema },
  responses: {
    200: { description: 'Note', content: { 'application/json': { schema: NoteSchema } } },
    401: unauthenticated,
    404: notFound,
    422: invalid,
  },
});

export const updateNoteRoute = createRoute({
  method: 'patch',
  path: '/v1/notes/{id}',
  operationId: 'updateNote',
  tags: ['notes'],
  summary: 'Ubah judul dan/atau isi note',
  security: bearerSecurity,
  request: {
    params: NoteParamsSchema,
    body: { required: true, content: { 'application/json': { schema: UpdateNoteBodySchema } } },
  },
  responses: {
    200: { description: 'Note diubah', content: { 'application/json': { schema: NoteSchema } } },
    401: unauthenticated,
    404: notFound,
    422: invalid,
  },
});

export const deleteNoteRoute = createRoute({
  method: 'delete',
  path: '/v1/notes/{id}',
  operationId: 'deleteNote',
  tags: ['notes'],
  summary: 'Hapus note',
  security: bearerSecurity,
  request: { params: NoteParamsSchema },
  responses: {
    204: { description: 'Note dihapus' },
    401: unauthenticated,
    404: notFound,
    422: invalid,
  },
});

export interface NoteRouteDeps {
  listNotes: ListNotes;
  createNote: CreateNote;
  getNote: GetNote;
  updateNote: UpdateNote;
  deleteNote: DeleteNote;
}

export function registerNoteRoutes(app: OpenAPIHono<AppEnv>, deps: NoteRouteDeps): void {
  app.openapi(listNotesRoute, async (c) => {
    const page = await deps.listNotes(c.var.user.id, c.req.valid('query'));
    return c.json({ items: page.items.map(toNoteDto), nextCursor: page.nextCursor }, 200);
  });

  app.openapi(createNoteRoute, async (c) => {
    const note = await deps.createNote({ userId: c.var.user.id, ...c.req.valid('json') });
    return c.json(toNoteDto(note), 201);
  });

  app.openapi(getNoteRoute, async (c) => {
    const note = await deps.getNote(c.var.user.id, c.req.valid('param').id);
    return c.json(toNoteDto(note), 200);
  });

  app.openapi(updateNoteRoute, async (c) => {
    const { id } = c.req.valid('param');
    const note = await deps.updateNote(c.var.user.id, id, c.req.valid('json'));
    return c.json(toNoteDto(note), 200);
  });

  app.openapi(deleteNoteRoute, async (c) => {
    await deps.deleteNote(c.var.user.id, c.req.valid('param').id);
    return c.body(null, 204);
  });
}
