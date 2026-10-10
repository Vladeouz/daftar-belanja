// Nilai env default untuk test. Nilai yang sudah di-set di shell tidak ditimpa.
const defaults: Record<string, string> = {
  NODE_ENV: 'test',
  LOG_LEVEL: 'silent',
  CORS_ORIGINS: 'http://localhost:8081',
  // Database utama lokal (docker compose). Integration test memakai `<nama>_test` (test/setup/db.ts).
  DATABASE_URL: 'postgres://template:template@localhost:5432/template',
  // Auth Emulator lokal (docker compose). Integration test membuat token lewat test/helpers/emulator-token.ts.
  FIREBASE_PROJECT_ID: 'demo-template',
  FIREBASE_AUTH_EMULATOR_HOST: 'localhost:9099',
  // pg-boss dijalankan langsung oleh test/int/jobs lewat startBoss(), bukan lewat env.
  RUN_WORKER: 'false',
  // Unit test memakai adapter palsu. test/int/ports memakai Storage Emulator lokal (docker compose)
  // lewat createFirebaseFileStorage() dengan bucket dan host di bawah.
  PUSH_ADAPTER: 'fake',
  STORAGE_ADAPTER: 'fake',
  FIREBASE_STORAGE_BUCKET: 'demo-template.appspot.com',
  FIREBASE_STORAGE_EMULATOR_HOST: 'localhost:9199',
};

for (const [key, value] of Object.entries(defaults)) {
  process.env[key] ??= value;
}
