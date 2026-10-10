import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Unit test saja. Integration test (`test/int/**/*.int.test.ts`) dijalankan lewat `test:int`.
    include: ['test/unit/**/*.test.ts'],
    setupFiles: ['test/setup/env.ts'],
    environment: 'node',
  },
});
