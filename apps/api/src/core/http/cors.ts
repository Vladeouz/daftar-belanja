import type { MiddlewareHandler } from 'hono';
import { cors as honoCors } from 'hono/cors';

// Hanya origin di `CORS_ORIGINS` yang mendapat header `Access-Control-Allow-Origin`.
// Origin lain tidak mendapat header itu, sehingga browser menolak request-nya.
export function cors(allowedOrigins: readonly string[]): MiddlewareHandler {
  const allowed = new Set(allowedOrigins);
  return honoCors({
    origin: (origin) => (allowed.has(origin) ? origin : null),
    allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Authorization', 'Content-Type'],
    exposeHeaders: ['X-Request-Id'],
    maxAge: 600,
  });
}
