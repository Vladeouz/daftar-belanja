import type { MiddlewareHandler } from 'hono';
import { type DestinationStream, type LevelWithSilent, type Logger, pino } from 'pino';
import type { AppEnv } from './http/context.js';

// FR-04 / NFR-04: field sensitif diredaksi di level mana pun sampai kedalaman 4.
// Wildcard pino hanya mencakup satu level, jadi setiap kedalaman ditulis eksplisit.
export const SENSITIVE_KEYS = [
  'authorization',
  'Authorization',
  'token',
  'idToken',
  'email',
  'phone',
];

export const REDACT_PATHS = SENSITIVE_KEYS.flatMap((key) => [
  key,
  `*.${key}`,
  `*.*.${key}`,
  `*.*.*.${key}`,
]);

export const REDACTED = '[REDACTED]';

export type LoggerOptions = {
  level?: LevelWithSilent;
};

export function createLogger(options: LoggerOptions = {}, destination?: DestinationStream): Logger {
  return pino(
    {
      level: options.level ?? 'info',
      redact: { paths: REDACT_PATHS, censor: REDACTED },
      timestamp: pino.stdTimeFunctions.isoTime,
    },
    destination,
  );
}

// Menyimpan child logger per request di `c.var.log` dan mencatat hasil setiap request.
// Hanya path yang dicatat, tanpa query string dan header, karena keduanya bisa berisi data sensitif.
export function requestLogger(logger: Logger): MiddlewareHandler<AppEnv> {
  return async (c, next) => {
    const log = logger.child({ requestId: c.var.requestId });
    c.set('log', log);
    const startedAt = performance.now();
    await next();
    log.info(
      {
        req: { method: c.req.method, path: c.req.path },
        res: { status: c.res.status },
        durationMs: Math.round(performance.now() - startedAt),
      },
      'request completed',
    );
  };
}
