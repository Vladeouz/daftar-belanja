import type { Logger } from 'pino';
import type { JobDefinition } from './boss.js';

export const HEARTBEAT_JOB = 'system.heartbeat';
// Setiap 5 menit (FR-07).
export const HEARTBEAT_CRON = '*/5 * * * *';

// Job contoh: hanya menulis log, sebagai bukti worker hidup.
export function heartbeatJob(logger: Logger): JobDefinition {
  return {
    name: HEARTBEAT_JOB,
    cron: HEARTBEAT_CRON,
    handler: async (jobs) => {
      for (const job of jobs) {
        logger.info({ job: job.name, jobId: job.id }, 'heartbeat');
      }
    },
  };
}
