// Entity user. Identitas dan password dikelola Firebase Auth; baris lokal disinkronkan dari ID token
// pada setiap request terautentikasi.
export interface User {
  id: string;
  firebaseUid: string;
  email: string | null;
  displayName: string | null;
  lastSeenAt: Date;
  createdAt: Date;
}

export interface UpsertUserInput {
  firebaseUid: string;
  email: string | null;
  displayName: string | null;
  seenAt: Date;
}

export interface UserRepository {
  // Membuat user bila `firebaseUid` belum ada, atau memperbarui email, nama, dan `lastSeenAt`.
  // Harus atomik: dua panggilan paralel dengan `firebaseUid` sama menghasilkan satu baris.
  upsertByFirebaseUid(input: UpsertUserInput): Promise<User>;
}
