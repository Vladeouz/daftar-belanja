import { describe, expect, it } from 'vitest';
import { createTestApp } from '../../../helpers/test-app.js';

describe('request context', () => {
  it('provides requestId and a request logger on c.var', async () => {
    const app = createTestApp();
    app.get('/test/context', (c) =>
      c.json({ requestId: c.var.requestId, hasLog: typeof c.var.log.info === 'function' }),
    );

    const res = await app.request('/test/context');
    const body = (await res.json()) as { requestId: string; hasLog: boolean };

    expect(body.hasLog).toBe(true);
    expect(body.requestId).toBeTruthy();
    expect(res.headers.get('x-request-id')).toBe(body.requestId);
  });
});
