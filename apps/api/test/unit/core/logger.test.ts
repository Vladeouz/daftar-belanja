import { Writable } from 'node:stream';
import { describe, expect, it } from 'vitest';
import { createLogger, REDACTED } from '../../../src/core/logger.js';
import { createTestApp } from '../../helpers/test-app.js';

function captureLogger() {
  const lines: Record<string, unknown>[] = [];
  const stream = new Writable({
    write(chunk, _encoding, callback) {
      for (const line of chunk.toString().split('\n').filter(Boolean)) lines.push(JSON.parse(line));
      callback();
    },
  });
  // Stream sinkron dari Writable: pino menulis langsung, tanpa buffer async.
  const logger = createLogger({ level: 'info' }, stream);
  return { logger, lines, raw: () => JSON.stringify(lines) };
}

const TOKEN = 'eyJhbGciOiJSUzI1NiJ9.secret-id-token.signature';
const EMAIL = 'budi@example.com';
const PHONE = '+6281234567890';

describe('logger redaction', () => {
  it('redacts the Authorization header', () => {
    const { logger, lines, raw } = captureLogger();

    logger.info({ req: { headers: { authorization: `Bearer ${TOKEN}` } } }, 'lower');
    logger.info({ headers: { Authorization: `Bearer ${TOKEN}` } }, 'upper');

    expect(raw()).not.toContain(TOKEN);
    expect(lines[0]).toMatchObject({ req: { headers: { authorization: REDACTED } } });
    expect(lines[1]).toMatchObject({ headers: { Authorization: REDACTED } });
  });

  it('redacts token, idToken, email, and phone at top level', () => {
    const { logger, lines, raw } = captureLogger();

    logger.info({ token: TOKEN, idToken: TOKEN, email: EMAIL, phone: PHONE }, 'top');

    expect(raw()).not.toContain(TOKEN);
    expect(raw()).not.toContain(EMAIL);
    expect(raw()).not.toContain(PHONE);
    expect(lines[0]).toMatchObject({
      token: REDACTED,
      idToken: REDACTED,
      email: REDACTED,
      phone: REDACTED,
    });
  });

  it('redacts sensitive fields nested up to four levels deep', () => {
    const { logger, lines, raw } = captureLogger();

    logger.info({ user: { id: 'u-1', email: EMAIL } }, 'one');
    logger.info({ body: { user: { phone: PHONE } } }, 'two');
    logger.info({ a: { b: { c: { idToken: TOKEN } } } }, 'three');

    expect(raw()).not.toContain(EMAIL);
    expect(raw()).not.toContain(PHONE);
    expect(raw()).not.toContain(TOKEN);
    expect(lines[0]).toMatchObject({ user: { id: 'u-1', email: REDACTED } });
    expect(lines[1]).toMatchObject({ body: { user: { phone: REDACTED } } });
    expect(lines[2]).toMatchObject({ a: { b: { c: { idToken: REDACTED } } } });
  });
});

describe('request logger', () => {
  it('logs method, path, status, duration, and request id', async () => {
    const { logger, lines } = captureLogger();

    await createTestApp({ logger }).request('/health');

    expect(lines.find((line) => line.msg === 'request completed')).toMatchObject({
      level: 30,
      requestId: expect.any(String),
      req: { method: 'GET', path: '/health' },
      res: { status: 200 },
      durationMs: expect.any(Number),
    });
  });

  it('does not log the Authorization header or the query string', async () => {
    const { logger, lines, raw } = captureLogger();

    await createTestApp({ logger }).request(`/health?email=${EMAIL}&token=${TOKEN}`, {
      headers: { authorization: `Bearer ${TOKEN}` },
    });

    expect(lines.find((line) => line.msg === 'request completed')).toMatchObject({
      req: { method: 'GET', path: '/health' },
    });
    expect(raw()).not.toContain(TOKEN);
    expect(raw()).not.toContain(EMAIL);
    expect(raw()).not.toContain('?');
  });
});
