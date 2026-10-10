import { afterEach, describe, expect, it, vi } from 'vitest';
import { createLogger } from '../../../src/core/logger.js';
import { closeServer, createShutdown, IDLE_SWEEP_MS } from '../../../src/core/shutdown.js';

const logger = createLogger({ level: 'silent' });

function fakes(options: { serverError?: Error; bossError?: Error; closerError?: Error } = {}) {
  const events: string[] = [];
  const server = {
    close: vi.fn((callback: (err?: Error) => void) => {
      events.push('server closed');
      callback(options.serverError);
    }),
  };
  const boss = {
    stop: vi.fn(async () => {
      events.push('pg-boss stopped');
      if (options.bossError) throw options.bossError;
    }),
  };
  const closer = vi.fn(async () => {
    events.push('connections closed');
    if (options.closerError) throw options.closerError;
  });
  const exit = vi.fn((code: number) => {
    events.push(`exit ${code}`);
  });
  return { events, server, boss, closer, exit };
}

describe('createShutdown', () => {
  it('closes the server, stops pg-boss gracefully, closes connections, then exits 0', async () => {
    const { events, server, boss, closer, exit } = fakes();

    await createShutdown({ logger, server, boss, closers: [closer], exit })('SIGTERM');

    expect(events).toEqual(['server closed', 'pg-boss stopped', 'connections closed', 'exit 0']);
    expect(boss.stop).toHaveBeenCalledWith({ graceful: true });
  });

  it('skips pg-boss when the worker is not running', async () => {
    const { events, server, closer, exit } = fakes();

    await createShutdown({ logger, server, boss: null, closers: [closer], exit })('SIGINT');

    expect(events).toEqual(['server closed', 'connections closed', 'exit 0']);
  });

  it.each([
    ['server', { serverError: new Error('close failed') }],
    ['pg-boss', { bossError: new Error('stop failed') }],
    ['connection', { closerError: new Error('end failed') }],
  ])('keeps going and exits 1 when the %s step fails', async (_step, failure) => {
    const { events, server, boss, closer, exit } = fakes(failure);

    await createShutdown({ logger, server, boss, closers: [closer], exit })('SIGTERM');

    expect(events).toEqual(['server closed', 'pg-boss stopped', 'connections closed', 'exit 1']);
  });

  it('runs once when signalled twice', async () => {
    const { server, boss, closer, exit } = fakes();
    const shutdown = createShutdown({ logger, server, boss, closers: [closer], exit });

    const first = shutdown('SIGTERM');
    const second = shutdown('SIGINT');
    await Promise.all([first, second]);

    expect(second).toBe(first);
    expect(server.close).toHaveBeenCalledOnce();
    expect(boss.stop).toHaveBeenCalledOnce();
    expect(exit).toHaveBeenCalledOnce();
  });
});

describe('closeServer', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('closes idle keep-alive connections until the server has closed', async () => {
    vi.useFakeTimers();
    let finishClose: (() => void) | undefined;
    const server = {
      close: vi.fn((callback: (err?: Error) => void) => {
        finishClose = () => callback();
      }),
      closeIdleConnections: vi.fn(),
    };

    const closed = closeServer(server);
    vi.advanceTimersByTime(IDLE_SWEEP_MS * 3);
    expect(server.closeIdleConnections).toHaveBeenCalledTimes(3);

    finishClose?.();
    await closed;
    vi.advanceTimersByTime(IDLE_SWEEP_MS * 3);
    expect(server.closeIdleConnections).toHaveBeenCalledTimes(3);
  });

  it('rejects with the close error', async () => {
    const error = new Error('not running');

    await expect(closeServer({ close: (callback) => callback(error) })).rejects.toBe(error);
  });
});
