import { randomUUID } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import type { ErrorBody } from '../../../src/core/http/errors.js';
import { useTestDb } from '../../helpers/db.js';
import { createEmulatorTokenVerifier, unsignedIdToken } from '../../helpers/emulator-token.js';
import { createTestApp } from '../../helpers/test-app.js';

// NFR-03: setiap route `/v1/*` yang terdaftar menolak request tanpa token yang valid.
// Daftar route diambil dari app sungguhan, jadi route baru otomatis ikut diuji.

const getDb = useTestDb();
const tokenVerifier = createEmulatorTokenVerifier();

// Route di luar `/v1` yang memang publik. Menambah route publik berarti menambahkannya di sini.
const PUBLIC_ROUTES = ['GET /health'];

// Daftar route dibaca saat test dikumpulkan; app ini tidak pernah menerima request.
// Middleware (`app.use`) terdaftar dengan method `ALL`; yang diuji hanya handler route.
const routes = [
  ...new Map(
    createTestApp()
      .routes.filter((r) => r.method !== 'ALL')
      .map((r) => [`${r.method} ${r.path}`, { method: r.method, path: r.path }]),
  ).values(),
];

// Request dikirim ke app dengan database test, agar route yang lupa dilindungi tidak menyentuh
// database utama.
const app = () => createTestApp({ db: getDb().db, tokenVerifier });

// `/v1/notes/:id` → `/v1/notes/<uuid>` agar validasi path tidak mendahului autentikasi.
const concretePath = (path: string) => path.replace(/:[^/]+/g, () => randomUUID());

const v1Routes = routes.filter((r) => r.path.startsWith('/v1/'));

describe('semua route /v1/* mewajibkan autentikasi', () => {
  it('menemukan route /v1/* yang terdaftar', () => {
    expect(v1Routes.map((r) => `${r.method} ${r.path}`)).toContain('GET /v1/me');
  });

  it('route di luar /v1 hanya route publik yang disengaja', () => {
    const outside = routes
      .filter((r) => !r.path.startsWith('/v1/'))
      .map((r) => `${r.method} ${r.path}`);
    expect(outside.sort()).toEqual([...PUBLIC_ROUTES].sort());
  });

  describe.each(v1Routes)('$method $path', ({ method, path }) => {
    const send = (headers: Record<string, string>) =>
      app().request(concretePath(path), {
        method,
        headers: { 'content-type': 'application/json', ...headers },
        // Body valid secara JSON agar tidak berhenti di parser sebelum autentikasi.
        ...(method === 'GET' || method === 'HEAD' ? {} : { body: '{}' }),
      });

    it('401 UNAUTHENTICATED tanpa header Authorization', async () => {
      const res = await send({});

      expect(res.status).toBe(401);
      expect(((await res.json()) as ErrorBody).error.code).toBe('UNAUTHENTICATED');
    });

    it('401 UNAUTHENTICATED dengan token tidak valid', async () => {
      const res = await send({ Authorization: `Bearer ${unsignedIdToken({ aud: 'demo-lain' })}` });

      expect(res.status).toBe(401);
      expect(((await res.json()) as ErrorBody).error.code).toBe('UNAUTHENTICATED');
    });
  });
});
