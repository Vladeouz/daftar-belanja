import { describe, expect, it } from 'vitest';
import type { ErrorBody } from '../../../src/core/http/errors.js';
import type { Page } from '../../../src/core/http/pagination.js';
import type { ShoppingItemDto } from '../../../src/features/shopping/http/shopping-items.route.js';
import type { UserDto } from '../../../src/features/users/http/me.route.js';
import { useTestDb } from '../../helpers/db.js';
import { createEmulatorTokenVerifier, signUp } from '../../helpers/emulator-token.js';
import { insertShoppingItem, insertShoppingItems } from '../../helpers/factories.js';
import { createTestApp } from '../../helpers/test-app.js';

// FR-01 sampai FR-04: barang belanja lewat HTTP dengan token dari Auth Emulator dan database test.

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

async function createItem(client: Client, body: { name: string; quantity?: number }) {
  const res = await client.send('POST', '/v1/shopping-items', body);
  expect(res.status).toBe(201);
  return json<ShoppingItemDto>(res);
}

async function listAll(client: Client) {
  const res = await client.send('GET', '/v1/shopping-items?limit=100');
  expect(res.status).toBe(200);
  return (await json<Page<ShoppingItemDto>>(res)).items;
}

describe('FR-01: tambah barang', () => {
  it('tanpa quantity tersimpan dengan quantity 1 dan isDone false', async () => {
    const a = await login();

    const item = await createItem(a, { name: 'Telur' });

    expect(item).toEqual({
      id: expect.stringMatching(/^[0-9a-f-]{36}$/),
      name: 'Telur',
      quantity: 1,
      isDone: false,
      createdAt: expect.stringMatching(/Z$/),
      updatedAt: item.createdAt,
    });
    expect(await listAll(a)).toEqual([item]);
  });

  it('dengan quantity menyimpan quantity itu', async () => {
    const a = await login();

    expect((await createItem(a, { name: 'Beras', quantity: 5 })).quantity).toBe(5);
  });

  it('"telur" saat "Telur" sudah ada → 409 CONFLICT dan tidak ada barang baru', async () => {
    const a = await login();
    const existing = await createItem(a, { name: 'Telur' });

    const res = await a.send('POST', '/v1/shopping-items', { name: 'telur' });

    expect(res.status).toBe(409);
    expect(await errorOf(res)).toEqual({
      code: 'CONFLICT',
      message: 'Shopping item name already exists',
    });
    expect(await listAll(a)).toEqual([existing]);
  });

  it('nama dirapikan sebelum cek keunikan: " TELUR " saat "Telur" sudah ada → 409', async () => {
    const a = await login();
    await createItem(a, { name: 'Telur' });

    const res = await a.send('POST', '/v1/shopping-items', { name: ' TELUR ' });

    expect(res.status).toBe(409);
  });

  it('nama yang sama boleh dipakai user lain', async () => {
    const a = await login();
    const b = await login();
    await createItem(a, { name: 'Telur' });

    expect((await createItem(b, { name: 'telur' })).name).toBe('telur');
  });

  it.each([
    ['nama berisi spasi saja', { name: ' \t\n ' }, 'too_small'],
    ['nama lebih dari 80 karakter', { name: 'x'.repeat(81) }, 'too_big'],
    ['nama kosong', { name: '' }, 'too_small'],
    ['nama tidak dikirim', { quantity: 2 }, 'required'],
  ])('%s → 422 details.name dan tidak ada barang baru', async (_name, body, code) => {
    const a = await login();

    const res = await a.send('POST', '/v1/shopping-items', body);

    expect(res.status).toBe(422);
    const error = await errorOf(res);
    expect(error.code).toBe('VALIDATION_ERROR');
    expect(error.details?.name).toEqual([expect.objectContaining({ code })]);
    expect(await listAll(a)).toEqual([]);
  });

  it('nama tepat 80 karakter setelah dirapikan diterima dan disimpan tanpa spasi tepi', async () => {
    const a = await login();

    const item = await createItem(a, { name: `  ${'x'.repeat(80)}  ` });

    expect(item.name).toBe('x'.repeat(80));
  });

  it.each([
    [0, 'too_small'],
    [1000, 'too_big'],
    [1.5, 'invalid_type'],
    ['2', 'invalid_type'],
  ])('quantity %j → 422 details.quantity', async (quantity, code) => {
    const a = await login();

    const res = await a.send('POST', '/v1/shopping-items', { name: 'Telur', quantity });

    expect(res.status).toBe(422);
    expect((await errorOf(res)).details?.quantity).toEqual([expect.objectContaining({ code })]);
  });
});

describe('FR-02: lihat dan filter', () => {
  async function collect(client: Client, query: string) {
    const pages: Page<ShoppingItemDto>[] = [];
    let url = `/v1/shopping-items?${query}`;
    for (;;) {
      const res = await client.send('GET', url);
      expect(res.status).toBe(200);
      const page = await json<Page<ShoppingItemDto>>(res);
      pages.push(page);
      if (page.nextCursor === null || pages.length > 10) return pages;
      url = `/v1/shopping-items?${query}&cursor=${page.nextCursor}`;
    }
  }

  it('25 barang campuran dibaca per 10 dengan status=open: hanya yang belum dibeli, tanpa duplikat, halaman terakhir tanpa halaman berikutnya', async () => {
    const a = await login();
    // Barang kelipatan 3 sudah dibeli: 8 sudah, 17 belum.
    const rows = await insertShoppingItems(getDb().db, a.userId, 25, (i) => i % 3 === 0);
    const open = rows.filter((r) => !r.isDone);
    expect(open).toHaveLength(17);

    const pages = await collect(a, 'limit=10&status=open');

    expect(pages.map((p) => p.items.length)).toEqual([10, 7]);
    expect(pages.at(-1)?.nextCursor).toBeNull();
    const items = pages.flatMap((p) => p.items);
    expect(items.every((i) => !i.isDone)).toBe(true);
    expect(new Set(items.map((i) => i.id)).size).toBe(17);
    // Terbaru lebih dulu.
    expect(items.map((i) => i.id)).toEqual(open.map((r) => r.id).reverse());
  });

  it('status=done hanya berisi yang sudah dibeli', async () => {
    const a = await login();
    const rows = await insertShoppingItems(getDb().db, a.userId, 25, (i) => i % 3 === 0);

    const pages = await collect(a, 'limit=10&status=done');

    const items = pages.flatMap((p) => p.items);
    expect(items.map((i) => i.id)).toEqual(
      rows
        .filter((r) => r.isDone)
        .map((r) => r.id)
        .reverse(),
    );
  });

  it('tanpa status (default all) dan status=all berisi semua barang', async () => {
    const a = await login();
    const rows = await insertShoppingItems(getDb().db, a.userId, 25, (i) => i % 3 === 0);
    const all = rows.map((r) => r.id).reverse();

    for (const query of ['limit=10', 'limit=10&status=all']) {
      const pages = await collect(a, query);
      expect(
        pages.map((p) => p.items.length),
        query,
      ).toEqual([10, 10, 5]);
      expect(pages.at(-1)?.nextCursor, query).toBeNull();
      expect(
        pages.flatMap((p) => p.items.map((i) => i.id)),
        query,
      ).toEqual(all);
    }
  });

  it('barang milik user lain tidak muncul di daftar', async () => {
    const a = await login();
    const b = await login();
    await insertShoppingItem(getDb().db, { userId: a.userId, name: 'Milik A' });
    await insertShoppingItem(getDb().db, {
      userId: a.userId,
      name: 'Milik A selesai',
      isDone: true,
    });
    const mine = await createItem(b, { name: 'Milik B' });

    for (const status of ['all', 'open', 'done']) {
      const page = await json<Page<ShoppingItemDto>>(
        await b.send('GET', `/v1/shopping-items?status=${status}`),
      );
      expect(page, status).toEqual({
        items: status === 'done' ? [] : [mine],
        nextCursor: null,
      });
    }
  });

  it('status tidak dikenal → 422 details.status', async () => {
    const a = await login();

    const res = await a.send('GET', '/v1/shopping-items?status=bought');

    expect(res.status).toBe(422);
    expect(Object.keys((await errorOf(res)).details ?? {})).toEqual(['status']);
  });

  it('cursor rusak → 422 details.cursor', async () => {
    const a = await login();

    const res = await a.send('GET', '/v1/shopping-items?cursor=xyz');

    expect(res.status).toBe(422);
    expect((await errorOf(res)).details).toEqual({
      cursor: [{ code: 'custom', message: 'Invalid cursor' }],
    });
  });
});

describe('FR-03: ubah dan tandai', () => {
  it('mengubah isDone menyimpan status dan field lain tidak berubah', async () => {
    const a = await login();
    const item = await createItem(a, { name: 'Telur', quantity: 3 });

    const res = await a.send('PATCH', `/v1/shopping-items/${item.id}`, { isDone: true });

    expect(res.status).toBe(200);
    const updated = await json<ShoppingItemDto>(res);
    expect(updated).toEqual({ ...item, isDone: true, updatedAt: updated.updatedAt });
    expect(Date.parse(updated.updatedAt)).toBeGreaterThanOrEqual(Date.parse(item.updatedAt));
    expect(await listAll(a)).toEqual([updated]);

    const back = await json<ShoppingItemDto>(
      await a.send('PATCH', `/v1/shopping-items/${item.id}`, { isDone: false }),
    );
    expect(back).toMatchObject({ name: 'Telur', quantity: 3, isDone: false });
  });

  it('mengubah nama dan quantity', async () => {
    const a = await login();
    const item = await createItem(a, { name: 'Telur' });

    const res = await a.send('PATCH', `/v1/shopping-items/${item.id}`, {
      name: ' Telur ayam ',
      quantity: 12,
    });

    expect(res.status).toBe(200);
    expect(await json(res)).toMatchObject({ name: 'Telur ayam', quantity: 12, isDone: false });
  });

  it('mengubah huruf besar-kecil nama sendiri diterima', async () => {
    const a = await login();
    const item = await createItem(a, { name: 'Telur' });

    const res = await a.send('PATCH', `/v1/shopping-items/${item.id}`, { name: 'TELUR' });

    expect(res.status).toBe(200);
    expect((await json<ShoppingItemDto>(res)).name).toBe('TELUR');
  });

  it('nama diubah menjadi nama barang lain milik sendiri → 409 dan barang tidak berubah', async () => {
    const a = await login();
    await createItem(a, { name: 'Beras' });
    const item = await createItem(a, { name: 'Telur' });

    const res = await a.send('PATCH', `/v1/shopping-items/${item.id}`, {
      name: 'beras',
      isDone: true,
    });

    expect(res.status).toBe(409);
    expect(await errorOf(res)).toEqual({
      code: 'CONFLICT',
      message: 'Shopping item name already exists',
    });
    expect((await listAll(a)).find((i) => i.id === item.id)).toEqual(item);
  });

  it('nama barang milik user lain boleh dipakai', async () => {
    const a = await login();
    const b = await login();
    await createItem(a, { name: 'Beras' });
    const item = await createItem(b, { name: 'Telur' });

    const res = await b.send('PATCH', `/v1/shopping-items/${item.id}`, { name: 'Beras' });

    expect(res.status).toBe(200);
  });

  it('barang milik user lain: PATCH dan DELETE → 404, barang tidak berubah', async () => {
    const a = await login();
    const b = await login();
    const item = await createItem(a, { name: 'Rahasia A' });

    for (const [method, body] of [
      ['PATCH', { isDone: true }],
      ['DELETE', undefined],
    ] as const) {
      const res = await b.send(method, `/v1/shopping-items/${item.id}`, body);
      expect(res.status, method).toBe(404);
      expect(await errorOf(res), method).toEqual({
        code: 'NOT_FOUND',
        message: 'Shopping item not found',
      });
    }

    expect(await listAll(a)).toEqual([item]);
  });

  it('DELETE barang sendiri 204, lalu hilang dari daftar dan DELETE ulang 404', async () => {
    const a = await login();
    const item = await createItem(a, { name: 'Hapus saya' });

    const res = await a.send('DELETE', `/v1/shopping-items/${item.id}`);

    expect(res.status).toBe(204);
    expect(await res.text()).toBe('');
    expect(await listAll(a)).toEqual([]);
    expect((await a.send('DELETE', `/v1/shopping-items/${item.id}`)).status).toBe(404);
  });

  it.each(['PATCH', 'DELETE'])('%s barang yang tidak ada → 404', async (method) => {
    const a = await login();

    const res = await a.send(
      method,
      `/v1/shopping-items/${MISSING_ID}`,
      method === 'PATCH' ? { isDone: true } : undefined,
    );

    expect(res.status).toBe(404);
    expect((await errorOf(res)).code).toBe('NOT_FOUND');
  });

  it('PATCH tanpa field → 422 details._root', async () => {
    const a = await login();
    const item = await createItem(a, { name: 'Telur' });

    const res = await a.send('PATCH', `/v1/shopping-items/${item.id}`, {});

    expect(res.status).toBe(422);
    expect(await errorOf(res)).toEqual({
      code: 'VALIDATION_ERROR',
      message: 'Request validation failed',
      details: {
        _root: [
          { code: 'custom', message: 'At least one of name, quantity, or isDone is required' },
        ],
      },
    });
  });

  it.each([
    ['name', { name: '   ' }],
    ['quantity', { quantity: 0 }],
    ['isDone', { isDone: 'ya' }],
  ])('PATCH dengan %s tidak valid → 422 dan barang tidak berubah', async (field, body) => {
    const a = await login();
    const item = await createItem(a, { name: 'Telur' });

    const res = await a.send('PATCH', `/v1/shopping-items/${item.id}`, body);

    expect(res.status).toBe(422);
    expect(Object.keys((await errorOf(res)).details ?? {})).toEqual([field]);
    expect(await listAll(a)).toEqual([item]);
  });

  it.each(['PATCH', 'DELETE'])('%s dengan id bukan UUID → details.id', async (method) => {
    const a = await login();

    const res = await a.send(
      method,
      '/v1/shopping-items/bukan-uuid',
      method === 'PATCH' ? { isDone: true } : undefined,
    );

    expect(res.status).toBe(422);
    expect(Object.keys((await errorOf(res)).details ?? {})).toEqual(['id']);
  });
});

describe('FR-04: hapus yang sudah dibeli', () => {
  it('3 barang sudah dibeli dan 2 belum: clear-done → deletedCount 3 dan 2 barang tersisa', async () => {
    const a = await login();
    // Barang 1, 3, 5 sudah dibeli; 2 dan 4 belum.
    const rows = await insertShoppingItems(getDb().db, a.userId, 5, (i) => i % 2 === 1);

    const res = await a.send('POST', '/v1/shopping-items/clear-done');

    expect(res.status).toBe(200);
    expect(await json(res)).toEqual({ deletedCount: 3 });
    expect((await listAll(a)).map((i) => i.id)).toEqual(
      rows
        .filter((r) => !r.isDone)
        .map((r) => r.id)
        .reverse(),
    );
  });

  it('barang sudah dibeli milik user lain tidak terhapus', async () => {
    const a = await login();
    const b = await login();
    const others = await insertShoppingItems(getDb().db, a.userId, 2, () => true);
    await insertShoppingItem(getDb().db, { userId: b.userId, name: 'Milik B', isDone: true });

    const res = await b.send('POST', '/v1/shopping-items/clear-done');

    expect(await json(res)).toEqual({ deletedCount: 1 });
    expect((await listAll(a)).map((i) => i.id)).toEqual(others.map((r) => r.id).reverse());
    expect(await listAll(b)).toEqual([]);
  });

  it('tanpa barang yang sudah dibeli → deletedCount 0 dan daftar tidak berubah', async () => {
    const a = await login();
    const item = await createItem(a, { name: 'Telur' });

    const res = await a.send('POST', '/v1/shopping-items/clear-done');

    expect(res.status).toBe(200);
    expect(await json(res)).toEqual({ deletedCount: 0 });
    expect(await listAll(a)).toEqual([item]);
  });
});
