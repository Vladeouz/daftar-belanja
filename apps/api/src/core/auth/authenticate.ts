import type { OpenAPIHono } from '@hono/zod-openapi';
import type { MiddlewareHandler } from 'hono';
import type { User } from '../../features/users/domain/user.js';
import type { AppEnv } from '../http/context.js';
import { AppError } from '../http/errors.js';
import type { TokenVerifier, VerifiedIdentity } from './firebase-admin.js';

export interface AuthenticateDeps {
  verifier: TokenVerifier;
  // Menyinkronkan identitas token ke tabel `users` (use case `syncUser`).
  resolveUser(identity: VerifiedIdentity): Promise<User>;
}

const BEARER = /^Bearer\s+(\S+)\s*$/i;

// Wajib untuk semua route `/v1/*` (dipasang di `app.ts`). Header tidak ada, bukan Bearer, atau
// token tidak valid/kedaluwarsa → `401 UNAUTHENTICATED`, tanpa menyentuh tabel `users`.
export function authenticate({
  verifier,
  resolveUser,
}: AuthenticateDeps): MiddlewareHandler<AppEnv> {
  return async (c, next) => {
    const match = BEARER.exec(c.req.header('Authorization') ?? '');
    if (!match?.[1]) {
      throw new AppError('UNAUTHENTICATED', 'Missing bearer token');
    }

    const identity = await verifier.verify(match[1]);
    if (!identity) {
      c.var.log.info('rejected invalid or expired ID token');
      throw new AppError('UNAUTHENTICATED', 'Invalid or expired token');
    }

    c.set('user', await resolveUser(identity));
    await next();
  };
}

// Nama security scheme OpenAPI. Route terautentikasi memakai `security: bearerSecurity`.
export const BEARER_AUTH = 'bearerAuth';
export const bearerSecurity = [{ [BEARER_AUTH]: [] }];

export function registerBearerAuth(app: OpenAPIHono<AppEnv>): void {
  app.openAPIRegistry.registerComponent('securitySchemes', BEARER_AUTH, {
    type: 'http',
    scheme: 'bearer',
    bearerFormat: 'JWT',
    description: 'Firebase ID token',
  });
}
