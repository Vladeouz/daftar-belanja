import { Writable } from 'node:stream';
import type { Job } from 'pg-boss';
import { describe, expect, it } from 'vitest';
import {
  HEARTBEAT_CRON,
  HEARTBEAT_JOB,
  heartbeatJob,
} from '../../../../src/core/jobs/heartbeat.job.js';
import { createLogger } from '../../../../src/core/logger.js';

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

function job(id: string): Job<object> {
  return {
    id,
    name: HEARTBEAT_JOB,
    data: {},
    expireInSeconds: 900,
    heartbeatSeconds: null,
    retryCount: 0,
    signal: new AbortController().signal,
  };
}

describe('heartbeatJob', () => {
  it('runs as system.heartbeat every 5 minutes', () => {
    const definition = heartbeatJob(createLogger({ level: 'silent' }));

    expect(definition.name).toBe('system.heartbeat');
    expect(definition.cron).toBe('*/5 * * * *');
    expect(HEARTBEAT_CRON).toBe('*/5 * * * *');
  });

  it('logs one heartbeat line per job', async () => {
    const { logger, lines } = captureLogger();

    await heartbeatJob(logger).handler([job('a'), job('b')]);

    expect(lines).toEqual([
      expect.objectContaining({ level: 30, msg: 'heartbeat', job: HEARTBEAT_JOB, jobId: 'a' }),
      expect.objectContaining({ level: 30, msg: 'heartbeat', job: HEARTBEAT_JOB, jobId: 'b' }),
    ]);
  });
});
