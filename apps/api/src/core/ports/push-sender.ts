// Port notifikasi push (D-06). Use case hanya bergantung pada interface ini; adapternya dipilih
// lewat env `PUSH_ADAPTER` di `create-ports.ts` (`fake` untuk development dan test, `fcm` untuk
// Firebase Cloud Messaging).

// Satu pesan ke satu perangkat. `token` adalah FCM registration token milik perangkat itu.
export interface PushMessage {
  token: string;
  title: string;
  body: string;
  // Data tambahan untuk aplikasi; FCM hanya menerima nilai string.
  data?: Record<string, string>;
}

// `invalid-token`: token tidak terdaftar lagi (aplikasi dihapus, token kedaluwarsa) atau formatnya
// salah. Pemanggil sebaiknya menghapus token itu dari penyimpanannya. Kegagalan lain dilempar.
export type PushResult = { status: 'sent'; messageId: string } | { status: 'invalid-token' };

export interface PushSender {
  send(message: PushMessage): Promise<PushResult>;
}
