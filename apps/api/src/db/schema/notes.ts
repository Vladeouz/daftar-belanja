import { sql } from 'drizzle-orm';
import { check, foreignKey, index, pgTable, text, uuid } from 'drizzle-orm/pg-core';
import { createdAt, id, updatedAt } from './columns.js';
import { users } from './users.js';

// CONTOH fitur notes: milik satu user, dihapus bersama user-nya. Batas panjang ditegakkan di
// database juga, bukan hanya di skema Zod route.
export const notes = pgTable(
  'notes',
  {
    id: id(),
    userId: uuid('user_id').notNull(),
    title: text('title').notNull(),
    body: text('body').notNull().default(''),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (table) => [
    foreignKey({
      name: 'notes_user_id_fk',
      columns: [table.userId],
      foreignColumns: [users.id],
    }).onDelete('cascade'),
    check('notes_title_length_check', sql`char_length(${table.title}) between 1 and 120`),
    check('notes_body_length_check', sql`char_length(${table.body}) <= 5000`),
    // Urutan pagination cursor: `created_at DESC, id DESC` per user. `nullsFirst()` wajib: tanpa itu
    // Drizzle menulis `DESC NULLS LAST`, yang tidak cocok dengan `ORDER BY ... DESC` sehingga
    // PostgreSQL tetap mengurutkan ulang hasilnya.
    index('notes_user_id_created_at_id_index').on(
      table.userId,
      table.createdAt.desc().nullsFirst(),
      table.id.desc().nullsFirst(),
    ),
  ],
);
