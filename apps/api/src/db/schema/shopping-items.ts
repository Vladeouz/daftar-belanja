import { sql } from 'drizzle-orm';
import {
  boolean,
  check,
  foreignKey,
  index,
  integer,
  pgTable,
  text,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import { createdAt, id, updatedAt } from './columns.js';
import { users } from './users.js';

// Barang di daftar belanja milik satu user, dihapus bersama user-nya (PRD bagian 4).
export const shoppingItems = pgTable(
  'shopping_items',
  {
    id: id(),
    userId: uuid('user_id').notNull(),
    name: text('name').notNull(),
    quantity: integer('quantity').notNull().default(1),
    isDone: boolean('is_done').notNull().default(false),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (table) => [
    foreignKey({
      name: 'shopping_items_user_id_fk',
      columns: [table.userId],
      foreignColumns: [users.id],
    }).onDelete('cascade'),
    check('shopping_items_name_length_check', sql`char_length(${table.name}) between 1 and 80`),
    check('shopping_items_quantity_range_check', sql`${table.quantity} between 1 and 999`),
    // Nama unik per user tanpa membedakan huruf besar dan kecil. Pelanggarannya dikenali lewat
    // nama constraint ini dan dijawab `409 CONFLICT` (D-01).
    uniqueIndex('shopping_items_user_id_name_unique').on(table.userId, sql`lower(${table.name})`),
    // Urutan pagination cursor: `created_at DESC, id DESC` per user (lihat tabel `notes`).
    index('shopping_items_user_id_created_at_id_index').on(
      table.userId,
      table.createdAt.desc().nullsFirst(),
      table.id.desc().nullsFirst(),
    ),
  ],
);
