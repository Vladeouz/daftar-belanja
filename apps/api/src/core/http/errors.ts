import { type OpenAPIHonoOptions, z } from '@hono/zod-openapi';
import type { ErrorHandler, NotFoundHandler } from 'hono';
import { HTTPException } from 'hono/http-exception';
import type { ContentfulStatusCode } from 'hono/utils/http-status';
import type { Logger } from 'pino';
import type { AppEnv } from './context.js';
import {
  ERROR_STATUS,
  type ErrorCode,
  ErrorCodeSchema,
  errorCodeForStatus,
} from './error-codes.js';

// Skema error PRD bagian 5. Setiap objek diberi nama komponen agar nama kelas Dart terkendali
// (tanpa nama, swagger_parser membuat kelas `Error` yang menutupi `Error` dari dart:core).
export const ErrorIssueSchema = z
  .object({
    code: z.string().openapi({ example: 'too_small' }),
    message: z.string(),
  })
  .openapi('ErrorIssue');

export const ApiErrorSchema = z
  .object({
    code: ErrorCodeSchema,
    message: z.string(),
    details: z.record(z.string(), z.array(ErrorIssueSchema)).optional(),
  })
  .openapi('ApiError');

export const ErrorBodySchema = z.object({ error: ApiErrorSchema }).openapi('ErrorBody');

export type ErrorIssue = z.infer<typeof ErrorIssueSchema>;
export type ErrorDetails = Record<string, ErrorIssue[]>;
export type ErrorBody = z.infer<typeof ErrorBodySchema>;

// Dipakai di `responses` setiap route: `422: errorResponse('Validasi gagal')`.
export function errorResponse(description: string) {
  return { description, content: { 'application/json': { schema: ErrorBodySchema } } };
}

export function errorBody(code: ErrorCode, message: string, details?: ErrorDetails): ErrorBody {
  return { error: details === undefined ? { code, message } : { code, message, details } };
}

// Error yang sengaja dilempar use case atau middleware. Status HTTP mengikuti `code`.
export class AppError extends Error {
  readonly status: ContentfulStatusCode;

  constructor(
    readonly code: ErrorCode,
    message: string,
  ) {
    super(message);
    this.name = 'AppError';
    this.status = ERROR_STATUS[code];
  }
}

export const ROOT_FIELD = '_root';
export const REQUIRED_ISSUE: ErrorIssue = { code: 'required', message: 'Required' };

// `input` adalah data mentah yang divalidasi. Zod 4 tidak menyertakan input di issue, jadi
// field yang tidak dikirim dideteksi dengan menelusuri path di data mentah.
function isMissing(input: unknown, path: readonly PropertyKey[]): boolean {
  let current = input;
  for (const key of path) {
    if (current === null || typeof current !== 'object') return true;
    current = (current as Record<PropertyKey, unknown>)[key];
  }
  return current === undefined;
}

// Membentuk `details` bagian 5: kunci path digabung titik (`items.0.name`) atau `_root`,
// nilai array `{ code, message }` dengan kode issue Zod, kecuali field tidak dikirim (`required`).
export function validationDetails(
  issues: readonly z.core.$ZodIssue[],
  input: unknown,
): ErrorDetails {
  const details: ErrorDetails = {};
  for (const issue of issues) {
    const hasPath = issue.path.length > 0;
    const field = hasPath ? issue.path.map(String).join('.') : ROOT_FIELD;
    const missing = hasPath && issue.code === 'invalid_type' && isMissing(input, issue.path);
    const entry = missing ? { ...REQUIRED_ISSUE } : { code: issue.code, message: issue.message };
    details[field] ??= [];
    details[field].push(entry);
  }
  return details;
}

export class ValidationError extends AppError {
  constructor(readonly details: ErrorDetails) {
    super('VALIDATION_ERROR', 'Request validation failed');
    this.name = 'ValidationError';
  }
}

// Dipasang sebagai `defaultHook` OpenAPIHono agar validasi body, path, dan query menghasilkan 422.
export const validationHook: OpenAPIHonoOptions<AppEnv>['defaultHook'] = (result) => {
  if (!result.success) {
    // @hono/zod-validator mengirim data mentah di `result.data` juga saat gagal, tetapi tipe
    // Hook di @hono/zod-openapi 1.6.3 tidak mendeklarasikannya. Dijaga test `required`.
    const input = (result as { data?: unknown }).data;
    throw new ValidationError(validationDetails(result.error.issues, input));
  }
};

export function createErrorHandler(rootLogger: Logger): ErrorHandler<AppEnv> {
  return (err, c) => {
    if (err instanceof ValidationError) {
      return c.json(errorBody(err.code, err.message, err.details), err.status);
    }
    if (err instanceof AppError) {
      return c.json(errorBody(err.code, err.message), err.status);
    }
    // HTTPException dari Hono, misalnya JSON rusak (400). Status 5xx diperlakukan sebagai
    // error tak terduga.
    if (err instanceof HTTPException && err.status < 500) {
      const code = errorCodeForStatus(err.status);
      return c.json(errorBody(code, err.message || code), err.status as ContentfulStatusCode);
    }
    (c.var.log ?? rootLogger).error({ err }, 'unhandled error');
    return c.json(errorBody('INTERNAL_ERROR', 'Internal server error'), 500);
  };
}

export const notFoundHandler: NotFoundHandler<AppEnv> = (c) =>
  c.json(errorBody('NOT_FOUND', 'Resource not found'), 404);
