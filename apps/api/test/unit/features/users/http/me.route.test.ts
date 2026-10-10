import { describe, expect, it } from 'vitest';
import type { TokenVerifier } from '../../../../../src/core/auth/firebase-admin.js';
import type { ErrorBody } from '../../../../../src/core/http/errors.js';
import { toUserDto } from '../../../../../src/features/users/http/me.route.js';
import { createTestApp } from '../../../../helpers/test-app.js';

const user = {
  id: '6f1c2f0e-8a3b-4c5d-9e7f-0a1b2c3d4e5f',
  firebaseUid: 'uid-1',
  email: 'a@example.com',
  displayName: null,
  lastSeenAt: new Date('2026-10-01T09:00:00Z'),
  createdAt: new Date('2026-10-01T08:00:00Z'),
};

describe('toUserDto', () => {
  it('exposes only id, email, displayName, and createdAt as ISO UTC', () => {
    expect(toUserDto(user)).toEqual({
      id: user.id,
      email: 'a@example.com',
      displayName: null,
      createdAt: '2026-10-01T08:00:00.000Z',
    });
  });
});

describe('GET /v1/me', () => {
  it('401 UNAUTHENTICATED without a token', async () => {
    const res = await createTestApp().request('/v1/me');

    expect(res.status).toBe(401);
    expect(((await res.json()) as ErrorBody).error.code).toBe('UNAUTHENTICATED');
  });

  it('401 UNAUTHENTICATED when the verifier rejects the token', async () => {
    const tokenVerifier: TokenVerifier = { verify: async () => null };

    const res = await createTestApp({ tokenVerifier }).request('/v1/me', {
      headers: { Authorization: 'Bearer token' },
    });

    expect(res.status).toBe(401);
  });

  it('documents bearer security and the 401 error schema in OpenAPI', () => {
    const doc = createTestApp().getOpenAPI31Document({
      openapi: '3.1.0',
      info: { title: 'test', version: '0' },
    });

    expect(doc.components?.securitySchemes?.bearerAuth).toMatchObject({
      type: 'http',
      scheme: 'bearer',
    });
    const operation = doc.paths?.['/v1/me']?.get;
    expect(operation?.operationId).toBe('getMe');
    expect(operation?.security).toEqual([{ bearerAuth: [] }]);
    expect(operation?.responses?.['401']).toMatchObject({
      content: { 'application/json': { schema: { $ref: '#/components/schemas/ErrorBody' } } },
    });
  });
});
