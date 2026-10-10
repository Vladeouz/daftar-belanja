import type { Logger } from 'pino';
import type { User } from '../../features/users/domain/user.js';

// Variabel per request yang tersedia lewat `c.var`.
export type AppEnv = {
  Variables: {
    requestId: string;
    log: Logger;
    // Diisi middleware `authenticate` untuk semua route `/v1/*`; tidak ada di route publik.
    user: User;
  };
};
