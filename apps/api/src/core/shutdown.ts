import type { Logger } from 'pino';

export type ClosableServer = {
  close(callback: (err?: Error) => void): unknown;
  // Ada di server HTTP/1 Node; server HTTP/2 tidak punya.
  closeIdleConnections?(): void;
};

// Selama menunggu, koneksi keep-alive dari request yang baru selesai ditutup.
export const IDLE_SWEEP_MS = 100;

// `close` menolak koneksi baru dan menunggu request yang sedang berjalan, tetapi koneksi
// keep-alive yang menjadi idle setelahnya baru ditutup Node saat `keepAliveTimeout` habis
// (beberapa detik). Koneksi idle ditutup berkala agar shutdown tidak menunggu selama itu.
export function closeServer(server: ClosableServer): Promise<void> {
  return new Promise<void>((resolve, reject) => {
    const sweep = setInterval(() => server.closeIdleConnections?.(), IDLE_SWEEP_MS);
    server.close((err) => {
      clearInterval(sweep);
      if (err) reject(err);
      else resolve();
    });
  });
}

export type ShutdownDeps = {
  logger: Logger;
  // Server HTTP (`serve()` dari @hono/node-server).
  server: ClosableServer;
  // pg-boss (`null` bila `RUN_WORKER` bukan `true`); berhenti graceful, menunggu job yang berjalan.
  boss: { stop(options: { graceful: boolean }): Promise<void> } | null;
  // Koneksi lain (pool database, firebase-admin), ditutup setelah pg-boss berhenti.
  closers: readonly (() => Promise<void>)[];
  exit: (code: number) => void;
};

// Urutan FR-07: berhenti menerima request (menunggu request yang sedang berjalan), menghentikan
// pg-boss, menutup koneksi lain, lalu keluar. Exit code 1 bila salah satu langkah gagal.
// Pemanggilan kedua (misalnya SIGINT setelah SIGTERM) mengembalikan proses yang sama.
export function createShutdown({ logger, server, boss, closers, exit }: ShutdownDeps) {
  let running: Promise<void> | undefined;

  async function run(signal: string): Promise<void> {
    logger.info({ signal }, 'shutting down');
    let failed = false;

    try {
      await closeServer(server);
    } catch (err) {
      failed = true;
      logger.error({ err }, 'failed to close server');
    }

    try {
      await boss?.stop({ graceful: true });
    } catch (err) {
      failed = true;
      logger.error({ err }, 'failed to stop pg-boss');
    }

    const results = await Promise.allSettled(closers.map((close) => close()));
    for (const result of results) {
      if (result.status === 'rejected') {
        failed = true;
        logger.error({ err: result.reason }, 'failed to close connection');
      }
    }

    logger.info({ signal }, 'shutdown complete');
    exit(failed ? 1 : 0);
  }

  return function shutdown(signal: string): Promise<void> {
    running ??= run(signal);
    return running;
  };
}
