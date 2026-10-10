import { describe, expect, it } from 'vitest';
import { createTestApp, TEST_ORIGIN } from '../../../helpers/test-app.js';

function preflight(origin: string) {
  return createTestApp().request('/health', {
    method: 'OPTIONS',
    headers: {
      origin,
      'access-control-request-method': 'POST',
      'access-control-request-headers': 'authorization,content-type',
    },
  });
}

describe('CORS', () => {
  it('allows a preflight from an origin in CORS_ORIGINS', async () => {
    const res = await preflight(TEST_ORIGIN);

    expect(res.status).toBe(204);
    expect(res.headers.get('access-control-allow-origin')).toBe(TEST_ORIGIN);
    expect(res.headers.get('access-control-allow-methods')).toContain('PATCH');
    expect(res.headers.get('access-control-allow-headers')?.toLowerCase()).toContain(
      'authorization',
    );
  });

  it('rejects a preflight from an origin outside CORS_ORIGINS', async () => {
    const res = await preflight('http://evil.example.com');

    expect(res.headers.get('access-control-allow-origin')).toBeNull();
  });

  it('adds the allow-origin header to simple requests only for allowed origins', async () => {
    const allowed = await createTestApp().request('/health', { headers: { origin: TEST_ORIGIN } });
    const other = await createTestApp().request('/health', {
      headers: { origin: 'http://localhost:9999' },
    });

    expect(allowed.headers.get('access-control-allow-origin')).toBe(TEST_ORIGIN);
    expect(allowed.headers.get('access-control-expose-headers')).toContain('X-Request-Id');
    expect(other.headers.get('access-control-allow-origin')).toBeNull();
  });

  it('supports several origins', async () => {
    const app = createTestApp({ corsOrigins: [TEST_ORIGIN, 'https://app.example.com'] });

    const res = await app.request('/health', { headers: { origin: 'https://app.example.com' } });

    expect(res.headers.get('access-control-allow-origin')).toBe('https://app.example.com');
  });
});
