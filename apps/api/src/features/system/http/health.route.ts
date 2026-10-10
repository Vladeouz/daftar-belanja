import { createRoute, type OpenAPIHono, z } from '@hono/zod-openapi';
import type { AppEnv } from '../../../core/http/context.js';

const HealthSchema = z.object({ status: z.literal('ok') }).openapi('Health');

export const healthRoute = createRoute({
  method: 'get',
  path: '/health',
  operationId: 'getHealth',
  tags: ['system'],
  summary: 'Health check',
  responses: {
    200: {
      description: 'API berjalan',
      content: { 'application/json': { schema: HealthSchema } },
    },
  },
});

export function registerHealthRoutes(app: OpenAPIHono<AppEnv>): void {
  app.openapi(healthRoute, (c) => c.json({ status: 'ok' as const }, 200));
}
