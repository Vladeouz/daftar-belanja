import { OpenAPIHono } from '@hono/zod-openapi';
import { requestId } from 'hono/request-id';
import type { Logger } from 'pino';
import { authenticate, registerBearerAuth } from './core/auth/authenticate.js';
import type { TokenVerifier } from './core/auth/firebase-admin.js';
import type { AppEnv } from './core/http/context.js';
import { cors } from './core/http/cors.js';
import { createErrorHandler, notFoundHandler, validationHook } from './core/http/errors.js';
import { requestLogger } from './core/logger.js';
import type { Ports } from './core/ports/create-ports.js';
import type { Database } from './db/client.js';
import { registerShoppingItemRoutes } from './features/shopping/http/shopping-items.route.js';
import { createDrizzleShoppingItemRepository } from './features/shopping/infrastructure/drizzle-shopping-item-repository.js';
import { clearDoneShoppingItems } from './features/shopping/usecases/clear-done-shopping-items.js';
import { createShoppingItem } from './features/shopping/usecases/create-shopping-item.js';
import { deleteShoppingItem } from './features/shopping/usecases/delete-shopping-item.js';
import { listShoppingItems } from './features/shopping/usecases/list-shopping-items.js';
import { updateShoppingItem } from './features/shopping/usecases/update-shopping-item.js';
import { registerHealthRoutes } from './features/system/http/health.route.js';
import { registerUserRoutes } from './features/users/http/me.route.js';
import { createDrizzleUserRepository } from './features/users/infrastructure/drizzle-user-repository.js';
import { syncUser } from './features/users/usecases/sync-user.js';

export type AppDeps = {
  logger: Logger;
  corsOrigins: readonly string[];
  db: Database;
  tokenVerifier: TokenVerifier;
  // Port push dan storage (D-06) untuk use case fitur; dirakit di sini seperti repository.
  // Belum ada fitur template yang memakainya.
  ports: Ports;
};

export function createApp({
  logger,
  corsOrigins,
  db,
  tokenVerifier,
}: AppDeps): OpenAPIHono<AppEnv> {
  const app = new OpenAPIHono<AppEnv>({ defaultHook: validationHook });

  app.use('*', requestId());
  app.use('*', requestLogger(logger));
  app.use('*', cors(corsOrigins));
  app.onError(createErrorHandler(logger));
  app.notFound(notFoundHandler);

  registerHealthRoutes(app);

  // Semua route `/v1/*` wajib login (NFR-03). Route publik didaftarkan di atas, di luar `/v1`.
  const users = createDrizzleUserRepository(db);
  app.use('/v1/*', authenticate({ verifier: tokenVerifier, resolveUser: syncUser({ users }) }));
  registerBearerAuth(app);
  registerUserRoutes(app);

  // Fitur: repository → use case → route. Fitur baru dirakit dengan pola yang sama.
  const shoppingItems = createDrizzleShoppingItemRepository(db);
  registerShoppingItemRoutes(app, {
    listShoppingItems: listShoppingItems({ shoppingItems }),
    createShoppingItem: createShoppingItem({ shoppingItems }),
    updateShoppingItem: updateShoppingItem({ shoppingItems }),
    deleteShoppingItem: deleteShoppingItem({ shoppingItems }),
    clearDoneShoppingItems: clearDoneShoppingItems({ shoppingItems }),
  });

  return app;
}
