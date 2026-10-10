import { describe, expect, it } from 'vitest';
import type { ErrorBody } from '../../../src/core/http/errors.js';
import type { Page } from '../../../src/core/http/pagination.js';
import type { NoteDto } from '../../../src/features/notes/http/notes.route.js';
import type { UserDto } from '../../../src/features/users/http/me.route.js';
import { useTestDb } from '../../helpers/db.js';
import { createEmulatorTokenVerifier, signUp } from '../../helpers/emulator-token.js';
import { insertNotes } from '../../helpers/factories.js';
import { createTestApp } from '../../helpers/test-app.js';

// FR-09: CRUD notes lewat HTTP dengan token dari Auth Emulator dan database test.

const getDb = useTestDb();
const tokenVerifier = createEmulatorTokenVerifier();

const app = () => createTestApp({ db: getDb().db, tokenVerifier });

const MISSING_ID = '00000000-0000-4000-8000-000000000000';

type Client = Awaited<ReturnType<typeof login>>;

// Akun baru di emulator beserta baris `users`-nya (dibuat lewat `GET /v1/me`).
async function login() {
  const { idToken } = await signUp();
  const send = (method: string, path: string, body?: unknown) =>
    app().request(path, {
      method,
      headers: {
        Authorization: `Bearer ${idToken}`,
        ...(body === undefined ? {} : { 'content-type': 'application/json' }),
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
  const me = (await (await send('GET', '/v1/me')).json()) as UserDto;
  return { userId: me.id, send };
}

const json = async <T>(res: Response) => (await res.json()) as T;
const errorOf = async (res: Response) => (await json<ErrorBody>(res)).error;

async function createNote(client: Client, body: { title: string; body?: string }) {
  const res = await client.send('POST', '/v1/notes', body);
  expect(res.status).toBe(201);
  return json<NoteDto>(res);
}

describe('CRUD notes', () => {
  it('POST membuat note 201 dengan body default kosong', async () => {
    const a = await login();

    const note = await createNote(a, { title: 'Belanja' });

    expect(note).toEqual({
      id: expect.stringMatching(/^[0-9a-f-]{36}$/),
      title: 'Belanja',
      body: '',
      createdAt: expect.stringMatching(/Z$/),
      updatedAt: note.createdAt,
    });
  });

  it('GET mengembalikan note milik sendiri', async () => {
    const a = await login();
    const note = await createNote(a, { title: 'Judul', body: 'Isi' });

    const res = await a.send('GET', `/v1/notes/${note.id}`);

    expect(res.status).toBe(200);
    expect(await json(res)).toEqual(note);
  });

  it('PATCH hanya mengubah field yang dikirim dan memperbarui updatedAt', async () => {
    const a = await login();
    const note = await createNote(a, { title: 'Lama', body: 'Isi lama' });

    const res = await a.send('PATCH', `/v1/notes/${note.id}`, { title: 'Baru' });

    expect(res.status).toBe(200);
    const updated = await json<NoteDto>(res);
    expect(updated).toMatchObject({ id: note.id, title: 'Baru', body: 'Isi lama' });
    expect(updated.createdAt).toBe(note.createdAt);
    expect(Date.parse(updated.updatedAt)).toBeGreaterThanOrEqual(Date.parse(note.updatedAt));
    expect(await json(await a.send('GET', `/v1/notes/${note.id}`))).toEqual(updated);
  });

  it('DELETE 204, lalu GET ulang 404', async () => {
    const a = await login();
    const note = await createNote(a, { title: 'Hapus saya' });

    const res = await a.send('DELETE', `/v1/notes/${note.id}`);

    expect(res.status).toBe(204);
    expect(await res.text()).toBe('');
    const again = await a.send('GET', `/v1/notes/${note.id}`);
    expect(again.status).toBe(404);
    expect(await errorOf(again)).toEqual({ code: 'NOT_FOUND', message: 'Note not found' });
  });

  it.each(['GET', 'PATCH', 'DELETE'])('%s note yang tidak ada → 404', async (method) => {
    const a = await login();

    const res = await a.send(
      method,
      `/v1/notes/${MISSING_ID}`,
      method === 'PATCH' ? { title: 'x' } : undefined,
    );

    expect(res.status).toBe(404);
    expect((await errorOf(res)).code).toBe('NOT_FOUND');
  });
});

describe('isolasi antar-user (D-07)', () => {
  it('user B mendapat 404 untuk GET, PATCH, dan DELETE note milik A; note A tidak berubah', async () => {
    const a = await login();
    const b = await login();
    const note = await createNote(a, { title: 'Rahasia A', body: 'Isi' });

    for (const [method, body] of [
      ['GET', undefined],
      ['PATCH', { title: 'Dibajak' }],
      ['DELETE', undefined],
    ] as const) {
      const res = await b.send(method, `/v1/notes/${note.id}`, body);
      expect(res.status, method).toBe(404);
      expect(await errorOf(res), method).toEqual({
        code: 'NOT_FOUND',
        message: 'Note not found',
      });
    }

    expect(await json(await a.send('GET', `/v1/notes/${note.id}`))).toEqual(note);
  });

  it('daftar user B tidak berisi note milik A', async () => {
    const a = await login();
    const b = await login();
    await createNote(a, { title: 'Milik A' });
    const mine = await createNote(b, { title: 'Milik B' });

    const page = await json<Page<NoteDto>>(await b.send('GET', '/v1/notes'));

    expect(page).toEqual({ items: [mine], nextCursor: null });
  });
});

describe('pagination', () => {
  async function collect(client: Client, limit: number) {
    const pages: Page<NoteDto>[] = [];
    let url = `/v1/notes?limit=${limit}`;
    for (;;) {
      const res = await client.send('GET', url);
      expect(res.status).toBe(200);
      const page = await json<Page<NoteDto>>(res);
      pages.push(page);
      if (page.nextCursor === null || pages.length > 10) return pages;
      url = `/v1/notes?limit=${limit}&cursor=${page.nextCursor}`;
    }
  }

  it('25 notes dengan limit=10: tiga halaman, tanpa duplikat, nextCursor terakhir null', async () => {
    const a = await login();
    const rows = await insertNotes(getDb().db, a.userId, 25);

    const pages = await collect(a, 10);

    expect(pages.map((p) => p.items.length)).toEqual([10, 10, 5]);
    expect(pages.at(-1)?.nextCursor).toBeNull();
    const ids = pages.flatMap((p) => p.items.map((n) => n.id));
    expect(new Set(ids).size).toBe(25);
    // Terbaru lebih dulu.
    expect(ids).toEqual(rows.map((r) => r.id).reverse());
  });

  it('limit default 20', async () => {
    const a = await login();
    await insertNotes(getDb().db, a.userId, 25);

    const page = await json<Page<NoteDto>>(await a.send('GET', '/v1/notes'));

    expect(page.items).toHaveLength(20);
    expect(page.nextCursor).not.toBeNull();
  });

  it('halaman kosong: items [] dan nextCursor null', async () => {
    const a = await login();

    expect(await json(await a.send('GET', '/v1/notes'))).toEqual({ items: [], nextCursor: null });
  });

  it('tidak ada duplikat bila beberapa note jatuh di milidetik yang sama', async () => {
    const a = await login();
    // Tiga note dikirim dengan mikrodetik berbeda di milidetik .123 (dibulatkan database menjadi
    // created_at yang sama), dua note dengan created_at identik, dan satu note lebih baru.
    const { rows } = await getDb().pool.query<{ id: string; title: string }>(
      `insert into notes (user_id, title, created_at) values
         ($1, 'ms-a', '2026-10-01T08:00:00.123100Z'),
         ($1, 'ms-b', '2026-10-01T08:00:00.123200Z'),
         ($1, 'ms-c', '2026-10-01T08:00:00.123400Z'),
         ($1, 'same-1', '2026-10-01T07:00:00Z'),
         ($1, 'same-2', '2026-10-01T07:00:00Z'),
         ($1, 'newest', '2026-10-01T09:00:00Z')
       returning id, title`,
      [a.userId],
    );
    const idDesc = (titles: string[]) =>
      rows
        .filter((r) => titles.includes(r.title))
        .map((r) => r.id)
        .sort()
        .reverse();

    const pages = await collect(a, 1);

    const items = pages.flatMap((p) => p.items);
    expect(items).toHaveLength(6);
    expect(new Set(items.map((n) => n.id)).size).toBe(6);
    expect(pages.at(-1)?.nextCursor).toBeNull();
    // Milidetik sama → urutan ditentukan id DESC.
    expect(items.map((n) => n.id)).toEqual([
      ...idDesc(['newest']),
      ...idDesc(['ms-a', 'ms-b', 'ms-c']),
      ...idDesc(['same-1', 'same-2']),
    ]);
    expect(items.slice(1, 4).map((n) => n.createdAt)).toEqual(
      Array(3).fill('2026-10-01T08:00:00.123Z'),
    );
  });
});

describe('validasi (422 VALIDATION_ERROR)', () => {
  it.each([
    ['title kosong', { title: '' }, 'too_small'],
    ['title hanya spasi', { title: ' \t\n ' }, 'too_small'],
    ['title lebih dari 120 karakter', { title: 'x'.repeat(121) }, 'too_big'],
    ['title tidak dikirim', { body: 'Isi' }, 'required'],
  ])('POST dengan %s → details.title', async (_name, body, code) => {
    const a = await login();

    const res = await a.send('POST', '/v1/notes', body);

    expect(res.status).toBe(422);
    const error = await errorOf(res);
    expect(error.code).toBe('VALIDATION_ERROR');
    expect(error.details?.title).toEqual([expect.objectContaining({ code })]);
  });

  it('title dirapikan sebelum disimpan dan sebelum cek panjang', async () => {
    const a = await login();

    const res = await a.send('POST', '/v1/notes', { title: `  ${'x'.repeat(120)}  ` });

    expect(res.status).toBe(201);
    expect((await json<NoteDto>(res)).title).toBe('x'.repeat(120));
  });

  it('POST dengan title tepat 120 karakter dan body 5000 karakter diterima', async () => {
    const a = await login();

    const res = await a.send('POST', '/v1/notes', {
      title: 'x'.repeat(120),
      body: 'y'.repeat(5000),
    });

    expect(res.status).toBe(201);
  });

  it('POST dengan body lebih dari 5000 karakter → details.body', async () => {
    const a = await login();

    const res = await a.send('POST', '/v1/notes', { title: 'Judul', body: 'y'.repeat(5001) });

    expect(res.status).toBe(422);
    expect((await errorOf(res)).details?.body).toEqual([
      expect.objectContaining({ code: 'too_big' }),
    ]);
  });

  it('POST tanpa body JSON → 422', async () => {
    const a = await login();

    const res = await a.send('POST', '/v1/notes');

    expect(res.status).toBe(422);
    expect((await errorOf(res)).code).toBe('VALIDATION_ERROR');
  });

  it('PATCH tanpa field → details._root', async () => {
    const a = await login();
    const note = await createNote(a, { title: 'Judul' });

    const res = await a.send('PATCH', `/v1/notes/${note.id}`, {});

    expect(res.status).toBe(422);
    expect(await errorOf(res)).toEqual({
      code: 'VALIDATION_ERROR',
      message: 'Request validation failed',
      details: {
        _root: [{ code: 'custom', message: 'At least one of title or body is required' }],
      },
    });
  });

  it('PATCH dengan title kosong → details.title', async () => {
    const a = await login();
    const note = await createNote(a, { title: 'Judul' });

    const res = await a.send('PATCH', `/v1/notes/${note.id}`, { title: '' });

    expect(res.status).toBe(422);
    expect(Object.keys((await errorOf(res)).details ?? {})).toEqual(['title']);
  });

  it('PATCH dengan title hanya spasi → details.title dan note tidak berubah', async () => {
    const a = await login();
    const note = await createNote(a, { title: 'Judul' });

    const res = await a.send('PATCH', `/v1/notes/${note.id}`, { title: '   ' });

    expect(res.status).toBe(422);
    expect((await errorOf(res)).details?.title).toEqual([
      expect.objectContaining({ code: 'too_small' }),
    ]);
    const after = await a.send('GET', `/v1/notes/${note.id}`);
    expect((await json<NoteDto>(after)).title).toBe('Judul');
  });

  it('cursor rusak → details.cursor', async () => {
    const a = await login();

    const res = await a.send('GET', '/v1/notes?cursor=xyz');

    expect(res.status).toBe(422);
    expect((await errorOf(res)).details).toEqual({
      cursor: [{ code: 'custom', message: 'Invalid cursor' }],
    });
  });

  it.each(['0', '101', 'abc'])('limit=%s → details.limit', async (limit) => {
    const a = await login();

    const res = await a.send('GET', `/v1/notes?limit=${limit}`);

    expect(res.status).toBe(422);
    expect(Object.keys((await errorOf(res)).details ?? {})).toEqual(['limit']);
  });

  it.each(['GET', 'PATCH', 'DELETE'])('%s dengan id bukan UUID → details.id', async (method) => {
    const a = await login();

    const res = await a.send(
      method,
      '/v1/notes/bukan-uuid',
      method === 'PATCH' ? { title: 'x' } : undefined,
    );

    expect(res.status).toBe(422);
    expect(Object.keys((await errorOf(res)).details ?? {})).toEqual(['id']);
  });
});
