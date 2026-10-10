import { z } from '@hono/zod-openapi';

// Pagination cursor PRD bagian 3: `?limit=20&cursor=<opaque>`, respons `{ items, nextCursor }`,
// urutan `created_at DESC, id DESC`. Cursor adalah base64url dari `createdAt|id`.

export const DEFAULT_PAGE_LIMIT = 20;
export const MAX_PAGE_LIMIT = 100;

// Posisi item terakhir di halaman. Semua timestamp di database berpresisi milidetik, jadi repository
// cukup memberi `Date` dari baris. Decoder tetap menerima 0–6 digit pecahan (string ISO 8601 UTC).
export type CursorPosition = { createdAt: string; id: string };

const ISO_UTC = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$/;
const SEPARATOR = '|';
const UuidSchema = z.uuid();

export function encodeCursor(position: { createdAt: Date | string; id: string }): string {
  const createdAt =
    position.createdAt instanceof Date ? position.createdAt.toISOString() : position.createdAt;
  return Buffer.from(`${createdAt}${SEPARATOR}${position.id}`, 'utf8').toString('base64url');
}

// Mengembalikan `null` untuk cursor rusak. Hanya bentuk kanonis hasil `encodeCursor` yang
// diterima, karena decoder base64url Node mengabaikan karakter asing tanpa error.
export function decodeCursor(cursor: string): CursorPosition | null {
  const raw = Buffer.from(cursor, 'base64url');
  if (cursor.length === 0 || raw.toString('base64url') !== cursor) return null;

  const parts = raw.toString('utf8').split(SEPARATOR);
  if (parts.length !== 2) return null;
  const [createdAt, id] = parts as [string, string];
  if (!ISO_UTC.test(createdAt) || Number.isNaN(Date.parse(createdAt))) return null;
  if (!UuidSchema.safeParse(id).success) return null;
  return { createdAt, id };
}

// Query `cursor` yang sudah di-decode. Cursor rusak → issue `custom` di `details.cursor` (422).
export const CursorSchema = z
  .string()
  .transform((value, ctx) => {
    const position = decodeCursor(value);
    if (position === null) {
      ctx.addIssue({ code: 'custom', message: 'Invalid cursor' });
      return z.NEVER;
    }
    return position;
  })
  .openapi({
    type: 'string',
    description: 'Nilai `nextCursor` dari halaman sebelumnya',
    example: 'MjAyNi0xMC0wMVQwODozMDowMC4wMDBafDNiMjQxMTAxLWUyYmItNDI1NS04Y2FmLTQxMzZjNTY2YTk2Mg',
  });

// Pakai langsung sebagai `request.query`, atau `PaginationQuerySchema.extend({ ... })` untuk
// menambah filter.
export const PaginationQuerySchema = z.object({
  // Tanpa `.openapi()`: override di sini menghapus minimum, maximum, dan default dari OpenAPI.
  limit: z.coerce.number().int().min(1).max(MAX_PAGE_LIMIT).default(DEFAULT_PAGE_LIMIT),
  cursor: CursorSchema.optional(),
});

export type PaginationQuery = z.infer<typeof PaginationQuerySchema>;

export type Page<T> = { items: T[]; nextCursor: string | null };

// Skema respons `{ items, nextCursor }`. `name` menjadi nama komponen OpenAPI dan kelas Dart,
// misalnya `pageSchema(NoteSchema, 'NotePage')`.
export function pageSchema<T extends z.ZodType>(item: T, name: string) {
  return z
    .object({
      items: z.array(item),
      nextCursor: z.string().nullable().openapi({ description: '`null` di halaman terakhir' }),
    })
    .openapi(name);
}

// Repository mengambil `limit + 1` baris dengan urutan `created_at DESC, id DESC`; baris
// tambahan hanya menandakan masih ada halaman berikutnya dan tidak dikembalikan.
export function buildPage<T>(
  rows: readonly T[],
  limit: number,
  positionOf: (item: T) => { createdAt: Date | string; id: string },
): Page<T> {
  const items = rows.slice(0, limit);
  const last = items.at(-1);
  const hasMore = rows.length > limit && last !== undefined;
  return { items, nextCursor: hasMore ? encodeCursor(positionOf(last)) : null };
}
