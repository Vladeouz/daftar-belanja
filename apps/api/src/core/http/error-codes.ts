import { z } from '@hono/zod-openapi';
import type { ContentfulStatusCode } from 'hono/utils/http-status';

// Daftar ErrorCode PRD bagian 5. Nilainya stabil: Flutter menerjemahkannya ke teks untuk user.
// Diekspor ke OpenAPI sebagai enum `ErrorCode`.
export const ERROR_CODES = [
  'BAD_REQUEST',
  'UNAUTHENTICATED',
  'FORBIDDEN',
  'NOT_FOUND',
  'CONFLICT',
  'VALIDATION_ERROR',
  'INTERNAL_ERROR',
] as const;

export type ErrorCode = (typeof ERROR_CODES)[number];

export const ErrorCodeSchema = z.enum(ERROR_CODES).openapi('ErrorCode');

export const ERROR_STATUS = {
  BAD_REQUEST: 400,
  UNAUTHENTICATED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  VALIDATION_ERROR: 422,
  INTERNAL_ERROR: 500,
} as const satisfies Record<ErrorCode, ContentfulStatusCode>;

// Status HTTP dari luar AppError (misalnya HTTPException Hono) dipetakan ke ErrorCode.
// Status 4xx lain menjadi BAD_REQUEST dan 5xx menjadi INTERNAL_ERROR.
export function errorCodeForStatus(status: number): ErrorCode {
  const match = ERROR_CODES.find((code) => ERROR_STATUS[code] === status);
  if (match) return match;
  return status >= 500 ? 'INTERNAL_ERROR' : 'BAD_REQUEST';
}
