import type { CursorPosition, Page } from '../../../core/http/pagination.js';

// Barang di daftar belanja milik satu user. Setiap akses selalu dibatasi `userId` pemiliknya;
// barang milik user lain diperlakukan sama dengan barang yang tidak ada (D-07).
export interface ShoppingItem {
  id: string;
  userId: string;
  name: string;
  quantity: number;
  isDone: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface NewShoppingItem {
  userId: string;
  name: string;
  quantity: number;
}

// Minimal satu field terisi (dijaga skema route).
export interface ShoppingItemChanges {
  name?: string;
  quantity?: number;
  isDone?: boolean;
}

// `open` = belum dibeli, `done` = sudah dibeli.
export const SHOPPING_ITEM_STATUSES = ['all', 'open', 'done'] as const;
export type ShoppingItemStatus = (typeof SHOPPING_ITEM_STATUSES)[number];

export interface ListShoppingItemsQuery {
  limit: number;
  cursor?: CursorPosition;
  status: ShoppingItemStatus;
}

// Dilempar repository bila nama (tanpa membedakan huruf besar dan kecil) sudah dipakai barang
// lain milik user yang sama. Use case mengubahnya menjadi `CONFLICT` (D-01).
export class ShoppingItemNameTakenError extends Error {
  constructor() {
    super('Shopping item name already exists');
    this.name = 'ShoppingItemNameTakenError';
  }
}

export interface ShoppingItemRepository {
  // Melempar `ShoppingItemNameTakenError` bila nama sudah ada.
  create(input: NewShoppingItem): Promise<ShoppingItem>;
  // Urutan `created_at DESC, id DESC`, mulai setelah `cursor`, difilter `status`.
  listByUser(userId: string, query: ListShoppingItemsQuery): Promise<Page<ShoppingItem>>;
  // `null` bila tidak ada atau bukan milik `userId`. Melempar `ShoppingItemNameTakenError` bila
  // nama baru sudah dipakai barang lain.
  update(userId: string, id: string, changes: ShoppingItemChanges): Promise<ShoppingItem | null>;
  // `false` bila tidak ada atau bukan milik `userId`.
  delete(userId: string, id: string): Promise<boolean>;
  // Hapus semua barang yang sudah dibeli (`isDone`) milik `userId`; mengembalikan jumlahnya.
  deleteDone(userId: string): Promise<number>;
}
