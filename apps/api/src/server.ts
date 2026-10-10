import { serve } from '@hono/node-server';
import { createApp } from './app.js';
import { createFirebaseAdmin, createFirebaseTokenVerifier } from './core/auth/firebase-admin.js';
import { type Env, EnvError, loadEnv } from './core/config/env.js';
import { startBoss } from './core/jobs/boss.js';
import { heartbeatJob } from './core/jobs/heartbeat.job.js';
import { createLogger } from './core/logger.js';
import { createPorts } from './core/ports/create-ports.js';
import { createShutdown } from './core/shutdown.js';
import { createDb } from './db/client.js';

function readEnv(): Env {
  try {
    return loadEnv();
  } catch (err) {
    // Logger belum ada karena LOG_LEVEL ikut divalidasi; pesan ditulis langsung ke stderr.
    if (err instanceof EnvError) {
      process.stderr.write(`${err.message}\n`);
      process.exit(1);
    }
    throw err;
  }
}

const env = readEnv();
const logger = createLogger({ level: env.LOG_LEVEL });
const database = createDb(env.DATABASE_URL);
const firebase = createFirebaseAdmin(env.FIREBASE_PROJECT_ID);
const app = createApp({
  logger,
  corsOrigins: env.CORS_ORIGINS,
  db: database.db,
  tokenVerifier: createFirebaseTokenVerifier(firebase.auth),
  ports: createPorts(env, firebase.app),
});

let boss: Awaited<ReturnType<typeof startBoss>>;
try {
  boss = await startBoss({
    databaseUrl: env.DATABASE_URL,
    runWorker: env.RUN_WORKER,
    logger,
    jobs: [heartbeatJob(logger)],
  });
} catch (err) {
  logger.fatal({ err }, 'failed to start pg-boss');
  await Promise.allSettled([database.close(), firebase.close()]);
  process.exit(1);
}

const server = serve({ fetch: app.fetch, port: env.PORT }, (info) => {
  logger.info(
    {
      port: info.port,
      nodeEnv: env.NODE_ENV,
      authEmulator: env.FIREBASE_AUTH_EMULATOR_HOST ?? null,
      worker: boss !== null,
      pushAdapter: env.PUSH_ADAPTER,
      storageAdapter: env.STORAGE_ADAPTER,
      storageEmulator: env.FIREBASE_STORAGE_EMULATOR_HOST ?? null,
    },
    'API listening',
  );
});

const shutdown = createShutdown({
  logger,
  server,
  boss,
  closers: [database.close, firebase.close],
  exit: (code) => process.exit(code),
});

process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);
