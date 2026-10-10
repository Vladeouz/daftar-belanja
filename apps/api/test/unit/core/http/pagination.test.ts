import { createRoute, z } from '@hono/zod-openapi';
import { describe, expect, it } from 'vitest';
import type { ErrorBody } from '../../../../src/core/http/errors.js';
import {
  buildPage,
  type CursorPosition,
  DEFAULT_PAGE_LIMIT,
  decodeCursor,
  encodeCursor,
  MAX_PAGE_LIMIT,
  type Page,
  PaginationQuerySchema,
  pageSchema,
} from '../../../../src/core/http/pagination.js';
import { createTestApp } from '../../../helpers/test-app.js';

const ID_A = '3b241101-e2bb-4255-8caf-4136c566a962';
const ID_B = '9f1c2d3e-4b5a-4c6d-8e7f-0a1b2c3d4e5f';

// Dua route berbeda memakai skema yang sama untuk membuktikan helper bisa dipakai ulang.
const ThingSchema = z.object({ id: z.uuid(), name: z.string() }).openapi('TestThing');
const OtherSchema = z.object({ id: z.uuid(), score: z.number() }).openapi('TestOther');

const listThingsRoute = createRoute({
  method: 'get',
  path: '/test/things',
  operationId: 'listTestThings',
  request: { query: PaginationQuerySchema },
  responses: {
    200: {
      description: 'ok',
      content: { 'application/json': { schema: pageSchema(ThingSchema, 'TestThingPage') } },
    },
  },
});

const listOthersRoute = createRoute({
  method: 'get',
  path: '/test/others',
  operationId: 'listTestOthers',
  request: { query: PaginationQuerySchema.extend({ minScore: z.coerce.number().optional() }) },
  responses: {
    200: {
      description: 'ok',
      content: { 'application/json': { schema: pageSchema(OtherSchema, 'TestOtherPage') } },
    },
  },
});

type Seen = { limit: number; cursor: CursorPosition | null };

function appWithPagedRoutes() {
  const app = createTestApp();
  app.openapi(listThingsRoute, (c) => {
    const { limit, cursor } = c.req.valid('query');
    const seen: Seen = { limit, cursor: cursor ?? null };
    const page: Page<z.infer<typeof ThingSchema>> = {
      items: [{ id: ID_A, name: JSON.stringify(seen) }],
      nextCursor: encodeCursor({ createdAt: '2026-10-01T08:30:00.000Z', id: ID_A }),
    };
    return c.json(page, 200);
  });
  app.openapi(listOthersRoute, (c) => {
    const { limit, minScore } = c.req.valid('query');
    return c.json({ items: [{ id: ID_B, score: minScore ?? limit }], nextCursor: null }, 200);
  });
  return app;
}

async function listThings(query: string) {
  const res = await appWithPagedRoutes().request(`/test/things${query}`);
  const body = (await res.json()) as Page<{ id: string; name: string }> & ErrorBody;
  return {
    res,
    body,
    seen: res.status === 200 ? (JSON.parse(body.items[0]?.name ?? '') as Seen) : null,
  };
}

describe('encodeCursor / decodeCursor', () => {
  it('round-trips createdAt and id', () => {
    const position = { createdAt: '2026-10-01T08:30:00.123Z', id: ID_A };
    const cursor = encodeCursor(position);

    expect(cursor).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(decodeCursor(cursor)).toEqual(position);
  });

  it('encodes base64url of `createdAt|id`', () => {
    const cursor = encodeCursor({ createdAt: '2026-10-01T08:30:00.000Z', id: ID_A });

    expect(Buffer.from(cursor, 'base64url').toString('utf8')).toBe(
      `2026-10-01T08:30:00.000Z|${ID_A}`,
    );
  });

  it('accepts a Date and encodes it as ISO 8601 UTC', () => {
    const cursor = encodeCursor({ createdAt: new Date('2026-10-01T08:30:00.123Z'), id: ID_A });

    expect(decodeCursor(cursor)).toEqual({ createdAt: '2026-10-01T08:30:00.123Z', id: ID_A });
  });

  it('keeps microsecond precision from PostgreSQL', () => {
    const position = { createdAt: '2026-10-01T08:30:00.123456Z', id: ID_B };

    expect(decodeCursor(encodeCursor(position))).toEqual(position);
  });

  const raw = (text: string) => Buffer.from(text, 'utf8').toString('base64url');

  it.each([
    ['empty string', ''],
    ['not base64url', 'xyz'],
    [
      'non-canonical base64url (foreign characters)',
      `${raw(`2026-10-01T08:30:00.000Z|${ID_A}`)}!!`,
    ],
    ['padding', `${Buffer.from(`2026-10-01T08:30:00.000Z|${ID_A}`).toString('base64')}==`],
    ['no separator', raw(`2026-10-01T08:30:00.000Z${ID_A}`)],
    ['extra part', raw(`2026-10-01T08:30:00.000Z|${ID_A}|x`)],
    ['id not a UUID', raw('2026-10-01T08:30:00.000Z|123')],
    ['timestamp without Z', raw(`2026-10-01T08:30:00.000|${ID_A}`)],
    ['timestamp with offset', raw(`2026-10-01T08:30:00.000+07:00|${ID_A}`)],
    ['impossible date', raw(`2026-13-45T08:30:00.000Z|${ID_A}`)],
    ['date only', raw(`2026-10-01|${ID_A}`)],
  ])('returns null for a broken cursor: %s', (_label, cursor) => {
    expect(decodeCursor(cursor)).toBeNull();
  });
});

describe('PaginationQuerySchema', () => {
  it(`defaults limit to ${DEFAULT_PAGE_LIMIT} and cursor to none`, async () => {
    const { res, seen } = await listThings('');

    expect(res.status).toBe(200);
    expect(seen).toEqual({ limit: DEFAULT_PAGE_LIMIT, cursor: null });
  });

  it.each([1, 50, MAX_PAGE_LIMIT])('accepts limit=%i', async (limit) => {
    const { res, seen } = await listThings(`?limit=${limit}`);

    expect(res.status).toBe(200);
    expect(seen?.limit).toBe(limit);
  });

  it.each([
    ['0', 'too_small'],
    ['-1', 'too_small'],
    [String(MAX_PAGE_LIMIT + 1), 'too_big'],
    ['1.5', 'invalid_type'],
    ['abc', 'invalid_type'],
  ])('rejects limit=%s with 422 details.limit (%s)', async (limit, code) => {
    const { res, body } = await listThings(`?limit=${limit}`);

    expect(res.status).toBe(422);
    expect(body.error.code).toBe('VALIDATION_ERROR');
    expect(Object.keys(body.error.details ?? {})).toEqual(['limit']);
    expect(body.error.details?.limit?.[0]?.code).toBe(code);
  });

  it('decodes a valid cursor before it reaches the handler', async () => {
    const cursor = encodeCursor({ createdAt: '2026-10-01T08:30:00.123456Z', id: ID_B });
    const { res, seen } = await listThings(`?limit=10&cursor=${cursor}`);

    expect(res.status).toBe(200);
    expect(seen).toEqual({
      limit: 10,
      cursor: { createdAt: '2026-10-01T08:30:00.123456Z', id: ID_B },
    });
  });

  it('rejects a broken cursor with 422 details.cursor', async () => {
    const { res, body } = await listThings('?cursor=xyz');

    expect(res.status).toBe(422);
    expect(body).toEqual({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed',
        details: { cursor: [{ code: 'custom', message: 'Invalid cursor' }] },
      },
    });
  });

  it('reports limit and cursor together when both are invalid', async () => {
    const { res, body } = await listThings('?limit=0&cursor=xyz');

    expect(res.status).toBe(422);
    expect(Object.keys(body.error.details ?? {}).sort()).toEqual(['cursor', 'limit']);
  });

  it('can be extended with extra filters by another route', async () => {
    const app = appWithPagedRoutes();

    const ok = await app.request('/test/others?minScore=7');
    expect(ok.status).toBe(200);
    expect(await ok.json()).toEqual({ items: [{ id: ID_B, score: 7 }], nextCursor: null });

    const bad = await app.request('/test/others?cursor=xyz');
    expect(bad.status).toBe(422);
    expect(((await bad.json()) as ErrorBody).error.details).toHaveProperty('cursor');
  });
});

describe('pageSchema', () => {
  it('validates `{ items, nextCursor }` with nullable nextCursor', () => {
    const schema = pageSchema(ThingSchema, 'TestThingPage');

    expect(schema.safeParse({ items: [], nextCursor: null }).success).toBe(true);
    expect(schema.safeParse({ items: [{ id: ID_A, name: 'a' }], nextCursor: 'abc' }).success).toBe(
      true,
    );
    expect(schema.safeParse({ items: [] }).success).toBe(false);
    expect(schema.safeParse({ items: [{ id: 'x', name: 'a' }], nextCursor: null }).success).toBe(
      false,
    );
  });

  it('exports query parameters and named page components to OpenAPI for every route', () => {
    const doc = appWithPagedRoutes().getOpenAPI31Document({
      openapi: '3.1.0',
      info: { title: 'test', version: '0' },
    });

    for (const path of ['/test/things', '/test/others']) {
      const params = doc.paths?.[path]?.get?.parameters as
        | { name: string; in: string; required?: boolean; schema: Record<string, unknown> }[]
        | undefined;
      const limit = params?.find((p) => p.name === 'limit');
      const cursor = params?.find((p) => p.name === 'cursor');

      expect(limit).toMatchObject({ in: 'query', required: false });
      expect(limit?.schema).toMatchObject({
        type: 'integer',
        minimum: 1,
        maximum: MAX_PAGE_LIMIT,
        default: DEFAULT_PAGE_LIMIT,
      });
      expect(cursor).toMatchObject({ in: 'query', required: false, schema: { type: 'string' } });
    }

    const schemas = doc.components?.schemas ?? {};
    for (const [name, item] of [
      ['TestThingPage', 'TestThing'],
      ['TestOtherPage', 'TestOther'],
    ] as const) {
      expect(schemas[name]).toMatchObject({
        type: 'object',
        required: ['items', 'nextCursor'],
        properties: {
          items: { type: 'array', items: { $ref: `#/components/schemas/${item}` } },
          nextCursor: { type: ['string', 'null'] },
        },
      });
    }
  });
});

describe('buildPage', () => {
  type Row = { id: string; createdAt: Date; n: number };

  // Baris berurutan `created_at DESC, id DESC`, seperti hasil query repository.
  const rows: Row[] = Array.from({ length: 25 }, (_, i) => ({
    id: `00000000-0000-4000-8000-${String(100 - i).padStart(12, '0')}`,
    createdAt: new Date(Date.UTC(2026, 9, 1, 8, 0, 25 - i)),
    n: i,
  }));

  // Repository palsu: ambil `limit + 1` baris setelah posisi cursor.
  function fetchPage(limit: number, cursor: string | null): Page<Row> {
    const after = cursor === null ? null : decodeCursor(cursor);
    const start = after === null ? 0 : rows.findIndex((r) => r.id === after.id) + 1;
    return buildPage(rows.slice(start, start + limit + 1), limit, (r) => r);
  }

  it('returns nextCursor null when there is no extra row', () => {
    const page = buildPage(rows.slice(0, 3), 3, (r) => r);

    expect(page.items).toHaveLength(3);
    expect(page.nextCursor).toBeNull();
  });

  it('drops the extra row and points nextCursor at the last returned item', () => {
    const page = buildPage(rows.slice(0, 4), 3, (r) => r);

    expect(page.items.map((r) => r.n)).toEqual([0, 1, 2]);
    expect(decodeCursor(page.nextCursor ?? '')).toEqual({
      createdAt: rows[2]?.createdAt.toISOString(),
      id: rows[2]?.id,
    });
  });

  it('returns an empty page with nextCursor null', () => {
    expect(buildPage([], 20, (r: Row) => r)).toEqual({ items: [], nextCursor: null });
  });

  it('walks 25 rows in pages of 10 without duplicates and ends with null', () => {
    const seen: number[] = [];
    const cursors: (string | null)[] = [];
    let cursor: string | null = null;
    do {
      const page = fetchPage(10, cursor);
      seen.push(...page.items.map((r) => r.n));
      cursor = page.nextCursor;
      cursors.push(cursor);
    } while (cursor !== null);

    expect(seen).toEqual(rows.map((r) => r.n));
    expect(new Set(seen).size).toBe(25);
    expect(cursors).toHaveLength(3);
    expect(cursors.at(-1)).toBeNull();
  });
});
