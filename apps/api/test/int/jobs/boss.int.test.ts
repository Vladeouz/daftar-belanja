import { Writable } from 'node:stream';
import type { PgBoss } from 'pg-boss';
import { afterEach, describe, expect, inject, it, vi } from 'vitest';
import { startBoss } from '../../../src/core/jobs/boss.js';
import {
  HEARTBEAT_CRON,
  HEARTBEAT_JOB,
  heartbeatJob,
} from '../../../src/core/jobs/heartbeat.job.js';
import { createLogger } from '../../../src/core/logger.js';
import { useTestDb } from '../../helpers/db.js';

const getDb = useTestDb();

function captureLogger() {
  const lines: Record<string, unknown>[] = [];
  const stream = new Writable({
    write(chunk, _encoding, callback) {
      lines.push(JSON.parse(chunk.toString()));
      callback();
    },
  });
  return { logger: createLogger({ level: 'info' }, stream), lines };
}

async function schemaExists(name: string): Promise<boolean> {
  const { rows } = await getDb().pool.query(
    'select 1 from information_schema.schemata where schema_name = $1',
    [name],
  );
  return rows.length > 0;
}

let boss: PgBoss | null = null;

afterEach(async () => {
  await boss?.stop({ graceful: false });
  boss = null;
});

describe('startBoss', () => {
  it('does not start pg-boss when RUN_WORKER is not true', async () => {
    const { logger, lines } = captureLogger();

    boss = await startBoss({
      databaseUrl: inject('databaseUrl'),
      runWorker: false,
      logger,
      jobs: [heartbeatJob(logger)],
      schema: 'pgboss_disabled',
    });

    expect(boss).toBeNull();
    // pg-boss membuat schema-nya saat start; schema yang tidak ada membuktikan tidak ada koneksi.
    expect(await schemaExists('pgboss_disabled')).toBe(false);
    expect(lines.map((line) => line.msg)).toContain('pg-boss disabled (RUN_WORKER is not true)');
  });

  it('starts pg-boss in schema pgboss and registers the heartbeat schedule', async () => {
    const { logger } = captureLogger();

    boss = await startBoss({
      databaseUrl: inject('databaseUrl'),
      runWorker: true,
      logger,
      jobs: [heartbeatJob(logger)],
    });

    expect(boss).not.toBeNull();
    expect(await schemaExists('pgboss')).toBe(true);
    expect(await boss?.getQueue(HEARTBEAT_JOB)).toMatchObject({ name: HEARTBEAT_JOB });
    const schedules = await boss?.getSchedules(HEARTBEAT_JOB);
    expect(schedules).toHaveLength(1);
    expect(schedules?.[0]).toMatchObject({
      name: HEARTBEAT_JOB,
      cron: HEARTBEAT_CRON,
      timezone: 'UTC',
    });
  });

  it('stops pg-boss and rethrows when a job cannot be registered', async () => {
    const { logger } = captureLogger();

    await expect(
      startBoss({
        databaseUrl: inject('databaseUrl'),
        runWorker: true,
        logger,
        jobs: [{ name: 'test.invalid', cron: 'not a cron', handler: async () => {} }],
      }),
    ).rejects.toThrow();

    // Koneksi pg-boss (application_name `pgboss:<id>`) ke database test sudah ditutup. Dibatasi ke
    // database ini karena API yang sedang berjalan (`RUN_WORKER=true`) punya koneksi pg-boss sendiri
    // ke database utama.
    await vi.waitFor(async () => {
      const { rows } = await getDb().pool.query(
        "select count(*)::int as n from pg_stat_activity where application_name like 'pgboss%' and datname = current_database()",
      );
      expect(rows[0].n).toBe(0);
    });
  });

  it('processes a sent system.heartbeat job with its handler', async () => {
    const { logger, lines } = captureLogger();

    boss = await startBoss({
      databaseUrl: inject('databaseUrl'),
      runWorker: true,
      logger,
      jobs: [heartbeatJob(logger)],
    });
    const jobId = await boss?.send(HEARTBEAT_JOB);

    expect(jobId).toEqual(expect.any(String));
    await vi.waitFor(
      () => {
        expect(lines).toContainEqual(
          expect.objectContaining({ msg: 'heartbeat', job: HEARTBEAT_JOB, jobId }),
        );
      },
      { timeout: 15_000, interval: 100 },
    );
    await vi.waitFor(
      async () => {
        const [job] = (await boss?.findJobs(HEARTBEAT_JOB, { id: jobId ?? '' })) ?? [];
        expect(job?.state).toBe('completed');
      },
      { timeout: 5_000, interval: 100 },
    );
  });
});
