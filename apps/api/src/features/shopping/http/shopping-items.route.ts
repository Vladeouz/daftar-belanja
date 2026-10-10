import { createRoute, type OpenAPIHono, z } from '@hono/zod-openapi';
import { bearerSecurity } from '../../../core/auth/authenticate.js';
import type { AppEnv } from '../../../core/http/context.js';
import { errorResponse } from '../../../core/http/errors.js';
import { PaginationQuerySchema, pageSchema } from '../../../core/http/pagination.js';
import { SHOPPING_ITEM_STATUSES, type ShoppingItem } from '../domain/shopping-item.js';
import type { ClearDoneShoppingItems } from '../usecases/clear-done-shopping-items.js';
import type { CreateShoppingItem } from '../usecases/create-shopping-item.js';
import type { DeleteShoppingItem } from '../usecases/delete-shopping-item.js';
import type { ListShoppingItems } from '../usecases/list-shopping-items.js';
import type { UpdateShoppingItem } from '../usecases/update-shopping-item.js';

// Batas sama dengan CHECK `shopping_items_name_length_check` dan
// `shopping_items_quantity_range_check`.
export const NAME_MAX = 80;
export const QUANTITY_MIN = 1;
export const QUANTITY_MAX = 999;

// Spasi di tepi dibuang sebelum cek panjang: nama berisi spasi saja → 422 `too_small`.
const Name = z.string().trim().min(1).max(NAME_MAX).openapi({ example: 'Telur' });
const Quantity = z.number().int().min(QUANTITY_MIN).max(QUANTITY_MAX).openapi({ example: 2 });

export const ShoppingItemSchema = z
  .object({
    id: z.uuid(),
    name: z.string(),
    quantity: z.number().int(),
    isDone: z.boolean(),
    createdAt: z.iso.datetime().openapi({ example: '2026-10-01T08:30:00.000Z' }),
    updatedAt: z.iso.datetime().openapi({ example: '2026-10-01T08:30:00.000Z' }),
  })
  .openapi('ShoppingItem');

export const ShoppingItemPageSchema = pageSchema(ShoppingItemSchema, 'ShoppingItemPage');

// `open` = belum dibeli, `done` = sudah dibeli.
export const ShoppingItemStatusSchema = z
  .enum(SHOPPING_ITEM_STATUSES)
  .openapi('ShoppingItemStatus', { description: '`open` belum dibeli, `done` sudah dibeli' });

const ListShoppingItemsQuerySchema = PaginationQuerySchema.extend({
  status: ShoppingItemStatusSchema.default('all'),
});

export const CreateShoppingItemBodySchema = z
  .object({ name: Name, quantity: Quantity.optional() })
  .openapi('CreateShoppingItemInput');

// Minimal satu field; body kosong `{}` → `details._root`.
export const UpdateShoppingItemBodySchema = z
  .object({ name: Name.optional(), quantity: Quantity.optional(), isDone: z.boolean().optional() })
  .refine(
    (value) =>
      value.name !== undefined || value.quantity !== undefined || value.isDone !== undefined,
    { message: 'At least one of name, quantity, or isDone is required' },
  )
  .openapi('UpdateShoppingItemInput');

export const ClearDoneShoppingItemsResultSchema = z
  .object({ deletedCount: z.number().int().min(0).openapi({ example: 3 }) })
  .openapi('ClearDoneShoppingItemsResult');

// `id` yang bukan UUID → 422 `details.id`.
const ShoppingItemParamsSchema = z.object({
  id: z.uuid().openapi({ param: { name: 'id', in: 'path' } }),
});

export type ShoppingItemDto = z.infer<typeof ShoppingItemSchema>;

export function toShoppingItemDto(item: ShoppingItem): ShoppingItemDto {
  return {
    id: item.id,
    name: item.name,
    quantity: item.quantity,
    isDone: item.isDone,
    createdAt: item.createdAt.toISOString(),
    updatedAt: item.updatedAt.toISOString(),
  };
}

const unauthenticated = errorResponse('Token tidak ada, tidak valid, atau kedaluwarsa');
const notFound = errorResponse('Barang tidak ada atau milik user lain');
const conflict = errorResponse('Nama barang sudah ada di daftar');
const invalid = errorResponse('Validasi gagal');

export const listShoppingItemsRoute = createRoute({
  method: 'get',
  path: '/v1/shopping-items',
  operationId: 'listShoppingItems',
  tags: ['shopping'],
  summary: 'Daftar barang belanja milik user, terbaru lebih dulu',
  security: bearerSecurity,
  request: { query: ListShoppingItemsQuerySchema },
  responses: {
    200: {
      description: 'Satu halaman barang',
      content: { 'application/json': { schema: ShoppingItemPageSchema } },
    },
    401: unauthenticated,
    422: invalid,
  },
});

export const createShoppingItemRoute = createRoute({
  method: 'post',
  path: '/v1/shopping-items',
  operationId: 'createShoppingItem',
  tags: ['shopping'],
  summary: 'Tambah barang belanja',
  security: bearerSecurity,
  request: {
    body: {
      required: true,
      content: { 'application/json': { schema: CreateShoppingItemBodySchema } },
    },
  },
  responses: {
    201: {
      description: 'Barang ditambahkan',
      content: { 'application/json': { schema: ShoppingItemSchema } },
    },
    401: unauthenticated,
    409: conflict,
    422: invalid,
  },
});

export const updateShoppingItemRoute = createRoute({
  method: 'patch',
  path: '/v1/shopping-items/{id}',
  operationId: 'updateShoppingItem',
  tags: ['shopping'],
  summary: 'Ubah nama, jumlah, dan/atau status barang',
  security: bearerSecurity,
  request: {
    params: ShoppingItemParamsSchema,
    body: {
      required: true,
      content: { 'application/json': { schema: UpdateShoppingItemBodySchema } },
    },
  },
  responses: {
    200: {
      description: 'Barang diubah',
      content: { 'application/json': { schema: ShoppingItemSchema } },
    },
    401: unauthenticated,
    404: notFound,
    409: conflict,
    422: invalid,
  },
});

export const deleteShoppingItemRoute = createRoute({
  method: 'delete',
  path: '/v1/shopping-items/{id}',
  operationId: 'deleteShoppingItem',
  tags: ['shopping'],
  summary: 'Hapus barang',
  security: bearerSecurity,
  request: { params: ShoppingItemParamsSchema },
  responses: {
    204: { description: 'Barang dihapus' },
    401: unauthenticated,
    404: notFound,
    422: invalid,
  },
});

export const clearDoneShoppingItemsRoute = createRoute({
  method: 'post',
  path: '/v1/shopping-items/clear-done',
  operationId: 'clearDoneShoppingItems',
  tags: ['shopping'],
  summary: 'Hapus semua barang yang sudah dibeli',
  security: bearerSecurity,
  responses: {
    200: {
      description: 'Jumlah barang yang dihapus',
      content: { 'application/json': { schema: ClearDoneShoppingItemsResultSchema } },
    },
    401: unauthenticated,
  },
});

export interface ShoppingItemRouteDeps {
  listShoppingItems: ListShoppingItems;
  createShoppingItem: CreateShoppingItem;
  updateShoppingItem: UpdateShoppingItem;
  deleteShoppingItem: DeleteShoppingItem;
  clearDoneShoppingItems: ClearDoneShoppingItems;
}

export function registerShoppingItemRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: ShoppingItemRouteDeps,
): void {
  app.openapi(listShoppingItemsRoute, async (c) => {
    const page = await deps.listShoppingItems(c.var.user.id, c.req.valid('query'));
    return c.json({ items: page.items.map(toShoppingItemDto), nextCursor: page.nextCursor }, 200);
  });

  app.openapi(createShoppingItemRoute, async (c) => {
    const item = await deps.createShoppingItem({ userId: c.var.user.id, ...c.req.valid('json') });
    return c.json(toShoppingItemDto(item), 201);
  });

  app.openapi(updateShoppingItemRoute, async (c) => {
    const { id } = c.req.valid('param');
    const item = await deps.updateShoppingItem(c.var.user.id, id, c.req.valid('json'));
    return c.json(toShoppingItemDto(item), 200);
  });

  app.openapi(deleteShoppingItemRoute, async (c) => {
    await deps.deleteShoppingItem(c.var.user.id, c.req.valid('param').id);
    return c.body(null, 204);
  });

  app.openapi(clearDoneShoppingItemsRoute, async (c) => {
    return c.json(await deps.clearDoneShoppingItems(c.var.user.id), 200);
  });
}
