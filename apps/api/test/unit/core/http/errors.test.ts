import { Writable } from 'node:stream';
import { createRoute, z } from '@hono/zod-openapi';
import { HTTPException } from 'hono/http-exception';
import { describe, expect, it } from 'vitest';
import { AppError, type ErrorBody, validationDetails } from '../../../../src/core/http/errors.js';
import { createLogger } from '../../../../src/core/logger.js';
import { createTestApp } from '../../../helpers/test-app.js';

const echoRoute = createRoute({
  method: 'post',
  path: '/test/echo/{id}',
  request: {
    params: z.object({ id: z.uuid() }),
    query: z.object({ limit: z.coerce.number().int().min(1).max(100).optional() }),
    body: {
      required: true,
      content: {
        'application/json': {
          schema: z.object({
            title: z.string().min(1).max(120),
            count: z.number().int().optional(),
            items: z.array(z.object({ name: z.string().min(1) })).optional(),
          }),
        },
      },
    },
  },
  responses: { 200: { description: 'ok' } },
});

const patchRoute = createRoute({
  method: 'patch',
  path: '/test/patch',
  request: {
    body: {
      required: true,
      content: {
        'application/json': {
          schema: z
            .object({ title: z.string().optional(), body: z.string().optional() })
            .refine((value) => Object.keys(value).length > 0, 'At least one field is required'),
        },
      },
    },
  },
  responses: { 200: { description: 'ok' } },
});

function captureLines() {
  const lines: Record<string, unknown>[] = [];
  const stream = new Writable({
    write(chunk, _encoding, callback) {
      for (const line of chunk.toString().split('\n').filter(Boolean)) lines.push(JSON.parse(line));
      callback();
    },
  });
  return { logger: createLogger({ level: 'info' }, stream), lines };
}

function appWithTestRoutes(logger = createLogger({ level: 'silent' })) {
  const app = createTestApp({ logger });
  app.openapi(echoRoute, (c) => c.json(c.req.valid('json'), 200));
  app.openapi(patchRoute, (c) => c.json(c.req.valid('json'), 200));
  app.get('/test/boom', () => {
    throw new Error('database password is hunter2');
  });
  app.get('/test/conflict', () => {
    throw new AppError('CONFLICT', 'Already exists');
  });
  app.get('/test/http-401', () => {
    throw new HTTPException(401, { message: 'Missing token' });
  });
  app.get('/test/http-503', () => {
    throw new HTTPException(503, { message: 'upstream secret detail' });
  });
  return app;
}

const VALID_ID = '3b241101-e2bb-4255-8caf-4136c566a962';

function sendJson(body: string, path = `/test/echo/${VALID_ID}`, method = 'POST') {
  return appWithTestRoutes().request(path, {
    method,
    headers: { 'content-type': 'application/json' },
    body,
  });
}

const postEcho = (body: unknown, path?: string) => sendJson(JSON.stringify(body), path);

async function readError(res: Response) {
  return ((await res.json()) as ErrorBody).error;
}

describe('error handler', () => {
  it('returns 404 NOT_FOUND in the standard format for unknown routes', async () => {
    const res = await appWithTestRoutes().request('/does-not-exist');

    expect(res.status).toBe(404);
    expect(await res.json()).toEqual({
      error: { code: 'NOT_FOUND', message: 'Resource not found' },
    });
  });

  it('returns 500 INTERNAL_ERROR without leaking the message, but logs it', async () => {
    const { logger, lines } = captureLines();

    const res = await appWithTestRoutes(logger).request('/test/boom');

    expect(res.status).toBe(500);
    const body = await res.json();
    expect(body).toEqual({ error: { code: 'INTERNAL_ERROR', message: 'Internal server error' } });
    expect(JSON.stringify(body)).not.toContain('hunter2');
    const logged = lines.find((line) => line.msg === 'unhandled error');
    expect(logged).toMatchObject({
      level: 50,
      requestId: expect.any(String),
      err: { message: 'database password is hunter2', stack: expect.any(String) },
    });
  });

  it('maps AppError to the status of its code, without details', async () => {
    const res = await appWithTestRoutes().request('/test/conflict');

    expect(res.status).toBe(409);
    expect(await res.json()).toEqual({ error: { code: 'CONFLICT', message: 'Already exists' } });
  });

  it('maps HTTPException 4xx to the matching ErrorCode', async () => {
    const res = await appWithTestRoutes().request('/test/http-401');

    expect(res.status).toBe(401);
    expect(await res.json()).toEqual({
      error: { code: 'UNAUTHENTICATED', message: 'Missing token' },
    });
  });

  it('treats HTTPException 5xx as unexpected errors', async () => {
    const res = await appWithTestRoutes().request('/test/http-503');

    expect(res.status).toBe(500);
    expect(await res.json()).toEqual({
      error: { code: 'INTERNAL_ERROR', message: 'Internal server error' },
    });
  });

  it('returns 400 BAD_REQUEST for malformed JSON', async () => {
    const res = await sendJson('{"title": ');

    expect(res.status).toBe(400);
    expect((await readError(res)).code).toBe('BAD_REQUEST');
  });
});

describe('Zod validation (422 details)', () => {
  it('passes valid requests through', async () => {
    const res = await postEcho({ title: 'Belanja', items: [{ name: 'Susu' }] });

    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ title: 'Belanja', items: [{ name: 'Susu' }] });
  });

  it('returns VALIDATION_ERROR with Zod issue codes per field', async () => {
    const res = await postEcho({ title: 'x'.repeat(121), count: 1.5 });

    expect(res.status).toBe(422);
    expect(await res.json()).toEqual({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed',
        details: {
          title: [{ code: 'too_big', message: expect.any(String) }],
          count: [{ code: 'invalid_type', message: expect.any(String) }],
        },
      },
    });
  });

  it('uses `required` for fields that were not sent', async () => {
    const res = await postEcho({});

    expect(res.status).toBe(422);
    expect((await readError(res)).details).toEqual({
      title: [{ code: 'required', message: 'Required' }],
    });
  });

  it('keeps invalid_type for fields sent with the wrong type, including null', async () => {
    const res = await postEcho({ title: null });

    expect((await readError(res)).details).toEqual({
      title: [{ code: 'invalid_type', message: expect.any(String) }],
    });
  });

  it('joins nested paths with dots', async () => {
    const res = await postEcho({ title: 'Belanja', items: [{ name: 'Susu' }, { name: '' }, {}] });

    expect((await readError(res)).details).toEqual({
      'items.1.name': [{ code: 'too_small', message: expect.any(String) }],
      'items.2.name': [{ code: 'required', message: 'Required' }],
    });
  });

  it('uses _root when the body is not an object', async () => {
    const res = await postEcho(['not', 'an', 'object']);

    expect((await readError(res)).details).toEqual({
      _root: [{ code: 'invalid_type', message: expect.any(String) }],
    });
  });

  it('uses _root for object-level refinements', async () => {
    const res = await sendJson('{}', '/test/patch', 'PATCH');

    expect(res.status).toBe(422);
    expect((await readError(res)).details).toEqual({
      _root: [{ code: 'custom', message: 'At least one field is required' }],
    });
  });

  it('validates path params', async () => {
    const res = await postEcho({ title: 'Belanja' }, '/test/echo/not-a-uuid');

    expect(res.status).toBe(422);
    expect((await readError(res)).details).toEqual({
      id: [{ code: 'invalid_format', message: expect.any(String) }],
    });
  });

  it('validates query params', async () => {
    const res = await postEcho({ title: 'Belanja' }, `/test/echo/${VALID_ID}?limit=101`);

    expect(res.status).toBe(422);
    expect((await readError(res)).details).toEqual({
      limit: [{ code: 'too_big', message: expect.any(String) }],
    });
  });
});

describe('validationDetails', () => {
  it('groups several issues on the same field', () => {
    const schema = z.object({
      code: z
        .string()
        .min(3)
        .regex(/^[A-Z]+$/),
    });
    const input = { code: 'a' };
    const result = schema.safeParse(input);

    expect(result.success).toBe(false);
    expect(validationDetails(result.error?.issues ?? [], input)).toEqual({
      code: [
        { code: 'too_small', message: expect.any(String) },
        { code: 'invalid_format', message: expect.any(String) },
      ],
    });
  });
});
