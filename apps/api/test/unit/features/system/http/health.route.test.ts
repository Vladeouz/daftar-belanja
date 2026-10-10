import { describe, expect, it } from 'vitest';
import { createTestApp } from '../../../../helpers/test-app.js';

describe('GET /health', () => {
  it('returns 200 {"status":"ok"} without authentication', async () => {
    const res = await createTestApp().request('/health');

    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ status: 'ok' });
  });

  it('sets an X-Request-Id header', async () => {
    const res = await createTestApp().request('/health');

    expect(res.headers.get('x-request-id')).toBeTruthy();
  });
});
