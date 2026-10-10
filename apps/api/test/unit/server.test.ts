import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const apiRoot = fileURLToPath(new URL('../..', import.meta.url));
// Start dingin `node --import tsx` bisa lebih dari 5 dtk (batas default Vitest), terutama di
// Windows saat mesin sibuk. Batas test dibuat lebih besar dari batas proses anak agar kegagalan
// selalu datang dari `spawnSync` (status `null`), bukan timeout Vitest yang acak.
const SPAWN_TIMEOUT_MS = 20_000;

describe('server startup', () => {
  it('exits with a message naming the missing env variable', {
    timeout: SPAWN_TIMEOUT_MS + 10_000,
  }, () => {
    const { CORS_ORIGINS: _omitted, ...env } = process.env;

    const result = spawnSync(process.execPath, ['--import', 'tsx', 'src/server.ts'], {
      cwd: apiRoot,
      env,
      encoding: 'utf8',
      timeout: SPAWN_TIMEOUT_MS,
    });

    expect(result.status).toBe(1);
    expect(result.stderr).toContain('Invalid environment variables');
    expect(result.stderr).toContain('CORS_ORIGINS');
  });
});
