import { describe, expect, it } from 'vitest';
import type { ErrorBody } from '../../../../../src/core/http/errors.js';
import { toNoteDto } from '../../../../../src/features/notes/http/notes.route.js';
import { createTestApp } from '../../../../helpers/test-app.js';

// Perilaku route dengan login dan database diuji di `test/int/notes/notes.int.test.ts`.

const ERROR_REF = { $ref: '#/components/schemas/ErrorBody' };

const openApi = () =>
  createTestApp().getOpenAPI31Document({
    openapi: '3.1.0',
    info: { title: 'test', version: '0' },
  });

describe('toNoteDto', () => {
  it('exposes id, title, body, and timestamps as ISO UTC without userId', () => {
    const dto = toNoteDto({
      id: '6f1c2f0e-8a3b-4c5d-9e7f-0a1b2c3d4e5f',
      userId: 'user-a',
      title: 'Judul',
      body: 'Isi',
      createdAt: new Date('2026-10-01T08:00:00Z'),
      updatedAt: new Date('2026-10-01T09:00:00Z'),
    });

    expect(dto).toEqual({
      id: '6f1c2f0e-8a3b-4c5d-9e7f-0a1b2c3d4e5f',
      title: 'Judul',
      body: 'Isi',
      createdAt: '2026-10-01T08:00:00.000Z',
      updatedAt: '2026-10-01T09:00:00.000Z',
    });
  });
});

describe('notes routes', () => {
  it('401 UNAUTHENTICATED without a token', async () => {
    const res = await createTestApp().request('/v1/notes');

    expect(res.status).toBe(401);
    expect(((await res.json()) as ErrorBody).error.code).toBe('UNAUTHENTICATED');
  });

  it('documents every operation with bearer security and error responses', () => {
    const paths = openApi().paths ?? {};
    const operations = {
      listNotes: [paths['/v1/notes']?.get, ['200', '401', '422']],
      createNote: [paths['/v1/notes']?.post, ['201', '401', '422']],
      getNote: [paths['/v1/notes/{id}']?.get, ['200', '401', '404', '422']],
      updateNote: [paths['/v1/notes/{id}']?.patch, ['200', '401', '404', '422']],
      deleteNote: [paths['/v1/notes/{id}']?.delete, ['204', '401', '404', '422']],
    } as const;

    for (const [operationId, [operation, statuses]] of Object.entries(operations)) {
      expect(operation?.operationId, operationId).toBe(operationId);
      expect(operation?.security, operationId).toEqual([{ bearerAuth: [] }]);
      expect(Object.keys(operation?.responses ?? {}).sort(), operationId).toEqual(statuses);
      for (const status of statuses.filter((s) => s.startsWith('4'))) {
        expect(operation?.responses?.[status], `${operationId} ${status}`).toMatchObject({
          content: { 'application/json': { schema: ERROR_REF } },
        });
      }
    }
  });

  it('names the schemas used by the Dart client', () => {
    const doc = openApi();
    const schemas = doc.components?.schemas ?? {};

    expect(Object.keys(schemas)).toEqual(
      expect.arrayContaining(['Note', 'NotePage', 'CreateNoteInput', 'UpdateNoteInput']),
    );
    expect(schemas.CreateNoteInput).toMatchObject({
      required: ['title'],
      properties: {
        title: { type: 'string', minLength: 1, maxLength: 120 },
        body: { type: 'string', maxLength: 5000 },
      },
    });
    const list = doc.paths?.['/v1/notes']?.get;
    expect(list?.responses?.['200']).toMatchObject({
      content: { 'application/json': { schema: { $ref: '#/components/schemas/NotePage' } } },
    });
    expect(list?.parameters).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          name: 'limit',
          in: 'query',
          schema: expect.objectContaining({ minimum: 1, maximum: 100, default: 20 }),
        }),
        expect.objectContaining({ name: 'cursor', in: 'query' }),
      ]),
    );
    expect(doc.paths?.['/v1/notes/{id}']?.get?.parameters).toEqual([
      expect.objectContaining({ name: 'id', in: 'path', required: true }),
    ]);
  });
});
