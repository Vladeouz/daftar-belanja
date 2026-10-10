import { describe, expect, it } from 'vitest';
import {
  ERROR_CODES,
  ERROR_STATUS,
  ErrorCodeSchema,
  errorCodeForStatus,
} from '../../../../src/core/http/error-codes.js';

describe('ErrorCode', () => {
  it('matches the list and HTTP statuses in PRD section 5', () => {
    expect(ERROR_STATUS).toEqual({
      BAD_REQUEST: 400,
      UNAUTHENTICATED: 401,
      FORBIDDEN: 403,
      NOT_FOUND: 404,
      CONFLICT: 409,
      VALIDATION_ERROR: 422,
      INTERNAL_ERROR: 500,
    });
    expect(ErrorCodeSchema.options).toEqual([...ERROR_CODES]);
  });

  it('maps known statuses to their code', () => {
    for (const code of ERROR_CODES) {
      expect(errorCodeForStatus(ERROR_STATUS[code])).toBe(code);
    }
  });

  it('maps other 4xx to BAD_REQUEST and other 5xx to INTERNAL_ERROR', () => {
    expect(errorCodeForStatus(405)).toBe('BAD_REQUEST');
    expect(errorCodeForStatus(413)).toBe('BAD_REQUEST');
    expect(errorCodeForStatus(503)).toBe('INTERNAL_ERROR');
  });
});
