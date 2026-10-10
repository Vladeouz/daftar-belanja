import { createRoute, type OpenAPIHono, z } from '@hono/zod-openapi';
import { bearerSecurity } from '../../../core/auth/authenticate.js';
import type { AppEnv } from '../../../core/http/context.js';
import { errorResponse } from '../../../core/http/errors.js';
import type { User } from '../domain/user.js';

export const UserSchema = z
  .object({
    id: z.uuid(),
    email: z.string().nullable(),
    displayName: z.string().nullable(),
    createdAt: z.iso.datetime().openapi({ example: '2026-10-01T08:30:00.000Z' }),
  })
  .openapi('User');

export type UserDto = z.infer<typeof UserSchema>;

export function toUserDto(user: User): UserDto {
  return {
    id: user.id,
    email: user.email,
    displayName: user.displayName,
    createdAt: user.createdAt.toISOString(),
  };
}

export const getMeRoute = createRoute({
  method: 'get',
  path: '/v1/me',
  operationId: 'getMe',
  tags: ['users'],
  summary: 'User yang sedang login',
  security: bearerSecurity,
  responses: {
    200: {
      description: 'User dari ID token; dibuat saat request pertama',
      content: { 'application/json': { schema: UserSchema } },
    },
    401: errorResponse('Token tidak ada, tidak valid, atau kedaluwarsa'),
  },
});

export function registerUserRoutes(app: OpenAPIHono<AppEnv>): void {
  // User sudah disinkronkan middleware `authenticate`; tidak perlu query lagi.
  app.openapi(getMeRoute, (c) => c.json(toUserDto(c.var.user), 200));
}
