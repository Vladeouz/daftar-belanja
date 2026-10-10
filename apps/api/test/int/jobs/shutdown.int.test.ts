import type { AddressInfo } from 'node:net';
import { serve } from '@hono/node-server';
import { Hono } from 'hono';
import { describe, expect, inject, it, vi } from 'vitest';
import { startBoss } from '../../../src/core/jobs/boss.js';
import { createLogger } from '../../../src/core/logger.js';
import { createShutdown } from '../../../src/core/shutdown.js';
import { useTestDb } from '../../helpers/db.js';

useTestDb();

function deferred() {
  let resolve!: () => void;
  const promise = new Promise<void>((r) => {
    resolve = r;
  });
  return { promise, resolve };
}

describe('shutdown (FR-07)', () => {
  it('stops accepting requests, waits for in-flight work, stops pg-boss, then exits', async () => {
    const logger = createLogger({ level: 'silent' });
    const events: string[] = [];

    // Request yang sedang berjalan saat shutdown dimulai.
    const requestStarted = deferred();
    const releaseRequest = deferred();
    const app = new Hono().get('/slow', async (c) => {
      requestStarted.resolve();
      await releaseRequest.promise;
      events.push('request finished');
      return c.json({ ok: true });
    });
    const server = await new Promise<ReturnType<typeof serve>>((resolve) => {
      const s = serve({ fetch: app.fetch, port: 0, hostname: '127.0.0.1' }, () => resolve(s));
    });
    const baseUrl = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;

    // Job yang sedang diproses saat shutdown dimulai.
    const jobStarted = deferred();
    const releaseJob = deferred();
    const boss = await startBoss({
      databaseUrl: inject('databaseUrl'),
      runWorker: true,
      logger,
      jobs: [
        {
          name: 'test.slow',
          handler: async () => {
            jobStarted.resolve();
            await releaseJob.promise;
            events.push('job finished');
          },
        },
      ],
    });
    if (!boss) throw new Error('pg-boss did not start');

    const stop = boss.stop.bind(boss);
    const stopSpy = vi.spyOn(boss, 'stop').mockImplementation(async (options) => {
      events.push('pg-boss stopping');
      await stop(options);
      events.push('pg-boss stopped');
    });
    const exit = vi.fn((code: number) => {
      events.push(`exit ${code}`);
    });
    const shutdown = createShutdown({
      logger,
      server,
      boss,
      closers: [
        async () => {
          events.push('connections closed');
        },
      ],
      exit,
    });

    const inFlight = fetch(`${baseUrl}/slow`);
    await requestStarted.promise;
    await boss.send('test.slow');
    await jobStarted.promise;

    const done = shutdown('SIGTERM');

    // 1. Berhenti menerima request: koneksi baru ditolak, request lama tetap berjalan.
    await expect(fetch(`${baseUrl}/slow`)).rejects.toThrow();
    expect(stopSpy).not.toHaveBeenCalled();

    releaseRequest.resolve();
    const response = await inFlight;
    expect(response.status).toBe(200);
    await response.json();

    // 2. pg-boss dihentikan setelah server tertutup, dan menunggu job yang sedang berjalan.
    await vi.waitFor(() => expect(stopSpy).toHaveBeenCalledWith({ graceful: true }));
    expect(exit).not.toHaveBeenCalled();

    releaseJob.resolve();
    await done;

    // 3. Koneksi lain ditutup, lalu keluar dengan kode 0.
    expect(events).toEqual([
      'request finished',
      'pg-boss stopping',
      'job finished',
      'pg-boss stopped',
      'connections closed',
      'exit 0',
    ]);
    expect(exit).toHaveBeenCalledOnce();
  });
});
