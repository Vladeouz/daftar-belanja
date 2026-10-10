import { describe, expect, it } from 'vitest';
import type { ErrorBody } from '../../../../../src/core/http/errors.js';
import { toShoppingItemDto } from '../../../../../src/features/shopping/http/shopping-items.route.js';
import { createTestApp } from '../../../../helpers/test-app.js';

// Perilaku route dengan login dan database diuji di `test/int/shopping/shopping-items.int.test.ts`.

const ERROR_REF = { $ref: '#/components/schemas/ErrorBody' };

const openApi = () =>
  createTestApp().getOpenAPI31Document({
    openapi: '3.1.0',
    info: { title: 'test', version: '0' },
  });

describe('toShoppingItemDto', () => {
  it('exposes the item fields and timestamps as ISO UTC without userId', () => {
    const dto = toShoppingItemDto({
      id: '6f1c2f0e-8a3b-4c5d-9e7f-0a1b2c3d4e5f',
      userId: 'user-a',
      name: 'Telur',
      quantity: 2,
      isDone: true,
      createdAt: new Date('2026-10-01T08:00:00Z'),
      updatedAt: new Date('2026-10-01T09:00:00Z'),
    });

    expect(dto).toEqual({
      id: '6f1c2f0e-8a3b-4c5d-9e7f-0a1b2c3d4e5f',
      name: 'Telur',
      quantity: 2,
      isDone: true,
      createdAt: '2026-10-01T08:00:00.000Z',
      updatedAt: '2026-10-01T09:00:00.000Z',
    });
  });
});

describe('shopping item routes', () => {
  it('401 UNAUTHENTICATED without a token', async () => {
    const res = await createTestApp().request('/v1/shopping-items');

    expect(res.status).toBe(401);
    expect(((await res.json()) as ErrorBody).error.code).toBe('UNAUTHENTICATED');
  });

  it('documents every operation with bearer security and error responses', () => {
    const paths = openApi().paths ?? {};
    const operations = {
      listShoppingItems: [paths['/v1/shopping-items']?.get, ['200', '401', '422']],
      createShoppingItem: [paths['/v1/shopping-items']?.post, ['201', '401', '409', '422']],
      updateShoppingItem: [
        paths['/v1/shopping-items/{id}']?.patch,
        ['200', '401', '404', '409', '422'],
      ],
      deleteShoppingItem: [paths['/v1/shopping-items/{id}']?.delete, ['204', '401', '404', '422']],
      clearDoneShoppingItems: [paths['/v1/shopping-items/clear-done']?.post, ['200', '401']],
    } as const;

    for (const [operationId, [operation, statuses]] of Object.entries(operations)) {
      expect(operation?.operationId, operationId).toBe(operationId);
      expect(operation?.tags, operationId).toEqual(['shopping']);
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
      expect.arrayContaining([
        'ShoppingItem',
        'ShoppingItemPage',
        'ShoppingItemStatus',
        'CreateShoppingItemInput',
        'UpdateShoppingItemInput',
        'ClearDoneShoppingItemsResult',
      ]),
    );
    expect(schemas.ClearDoneShoppingItemsResult).toMatchObject({
      required: ['deletedCount'],
      properties: { deletedCount: { type: 'integer', minimum: 0 } },
    });
    expect(schemas.CreateShoppingItemInput).toMatchObject({
      required: ['name'],
      properties: {
        name: { type: 'string', minLength: 1, maxLength: 80 },
        quantity: { type: 'integer', minimum: 1, maximum: 999 },
      },
    });
    expect(schemas.ShoppingItemStatus).toMatchObject({ enum: ['all', 'open', 'done'] });
    const list = doc.paths?.['/v1/shopping-items']?.get;
    expect(list?.responses?.['200']).toMatchObject({
      content: {
        'application/json': { schema: { $ref: '#/components/schemas/ShoppingItemPage' } },
      },
    });
    expect(list?.parameters).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          name: 'limit',
          in: 'query',
          schema: expect.objectContaining({ minimum: 1, maximum: 100, default: 20 }),
        }),
        expect.objectContaining({ name: 'cursor', in: 'query' }),
        expect.objectContaining({
          name: 'status',
          in: 'query',
          required: false,
          schema: { $ref: '#/components/schemas/ShoppingItemStatus' },
        }),
      ]),
    );
    expect(doc.paths?.['/v1/shopping-items/{id}']?.patch?.parameters).toEqual([
      expect.objectContaining({ name: 'id', in: 'path', required: true }),
    ]);
  });
});
