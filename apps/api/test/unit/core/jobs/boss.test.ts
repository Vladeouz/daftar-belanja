import { describe, expect, it } from 'vitest';
import { startBoss } from '../../../../src/core/jobs/boss.js';
import { createLogger } from '../../../../src/core/logger.js';

// Start sungguhan, jadwal, dan pemrosesan job diuji di test/int/jobs/boss.int.test.ts.
describe('startBoss', () => {
  it('returns null without connecting when runWorker is false', async () => {
    // Port 1 tidak pernah menerima koneksi; percobaan koneksi apa pun akan gagal.
    const boss = await startBoss({
      databaseUrl: 'postgres://nobody:nothing@127.0.0.1:1/none',
      runWorker: false,
      logger: createLogger({ level: 'silent' }),
      jobs: [{ name: 'test.never', handler: async () => {} }],
    });

    expect(boss).toBeNull();
  });
});
