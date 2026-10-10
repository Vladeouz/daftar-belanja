import { type Job, PgBoss } from 'pg-boss';
import type { Logger } from 'pino';

// Satu job pg-boss: nama queue, handler, dan jadwal cron opsional (UTC).
// Contoh: `core/jobs/heartbeat.job.ts`. Job baru didaftarkan di `server.ts`.
export type JobDefinition<T extends object = object> = {
  name: string;
  cron?: string;
  handler: (jobs: Job<T>[]) => Promise<void>;
};

export type StartBossOptions = {
  databaseUrl: string;
  runWorker: boolean;
  logger: Logger;
  jobs: readonly JobDefinition[];
  // Schema PostgreSQL tabel pg-boss, dikelola pg-boss sendiri (bukan migrasi Drizzle).
  schema?: string;
};

export const BOSS_SCHEMA = 'pgboss';

// D-05: pg-boss berjalan di proses API hanya bila `RUN_WORKER=true`; selain itu mengembalikan
// `null` tanpa membuka koneksi. Setelah start, setiap job punya queue, jadwal (bila ada `cron`),
// dan worker.
export async function startBoss({
  databaseUrl,
  runWorker,
  logger,
  jobs,
  schema = BOSS_SCHEMA,
}: StartBossOptions): Promise<PgBoss | null> {
  if (!runWorker) {
    logger.info('pg-boss disabled (RUN_WORKER is not true)');
    return null;
  }

  const boss = new PgBoss({ connectionString: databaseUrl, schema });
  // Tanpa listener `error`, error di pemeliharaan pg-boss menjadi unhandled dan mematikan proses.
  boss.on('error', (err) => logger.error({ err }, 'pg-boss error'));
  await boss.start();

  try {
    for (const job of jobs) {
      await boss.createQueue(job.name);
      if (job.cron) {
        await boss.schedule(job.name, job.cron);
      }
      await boss.work(job.name, async (batch) => {
        await job.handler(batch as Job<object>[]);
      });
    }
  } catch (err) {
    await boss.stop({ graceful: false });
    throw err;
  }

  logger.info({ jobs: jobs.map((job) => job.name) }, 'pg-boss started');
  return boss;
}
