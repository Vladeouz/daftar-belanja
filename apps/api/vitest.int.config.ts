import { defineConfig } from 'vitest/config';

// Integration test ke PostgreSQL di Docker (`docker compose up -d --wait`).
export default defineConfig({
  test: {
    include: ['test/int/**/*.int.test.ts'],
    setupFiles: ['test/setup/env.ts'],
    globalSetup: ['test/setup/db.ts'],
    environment: 'node',
    // Semua file berbagi satu database test yang di-TRUNCATE sebelum setiap test.
    fileParallelism: false,
    testTimeout: 20_000,
    hookTimeout: 60_000,
  },
});
