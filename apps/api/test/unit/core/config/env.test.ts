import { describe, expect, it } from 'vitest';
import { EnvError, loadDatabaseUrl, loadEnv } from '../../../../src/core/config/env.js';

const DATABASE_URL = 'postgres://template:template@localhost:5432/template';
const base = {
  CORS_ORIGINS: 'http://localhost:8081',
  DATABASE_URL,
  FIREBASE_PROJECT_ID: 'demo-template',
};

describe('loadEnv', () => {
  it('applies defaults', () => {
    expect(loadEnv(base)).toEqual({
      NODE_ENV: 'development',
      PORT: 3000,
      LOG_LEVEL: 'info',
      CORS_ORIGINS: ['http://localhost:8081'],
      DATABASE_URL,
      FIREBASE_PROJECT_ID: 'demo-template',
      RUN_WORKER: false,
      PUSH_ADAPTER: 'none',
      STORAGE_ADAPTER: 'none',
    });
  });

  it('accepts the push and storage adapters', () => {
    const env = loadEnv({
      ...base,
      PUSH_ADAPTER: 'fcm',
      STORAGE_ADAPTER: 'firebase',
      FIREBASE_STORAGE_BUCKET: 'demo-template.appspot.com',
    });

    expect(env.PUSH_ADAPTER).toBe('fcm');
    expect(env.STORAGE_ADAPTER).toBe('firebase');
    expect(env.FIREBASE_STORAGE_BUCKET).toBe('demo-template.appspot.com');
  });

  it.each([
    ['PUSH_ADAPTER', 'none'],
    ['PUSH_ADAPTER', 'fake'],
    ['PUSH_ADAPTER', 'fcm'],
    ['STORAGE_ADAPTER', 'none'],
    ['STORAGE_ADAPTER', 'fake'],
  ])('accepts %s=%s outside production', (key, value) => {
    expect(loadEnv({ ...base, [key]: value })[key as 'PUSH_ADAPTER']).toBe(value);
  });

  it.each(['PUSH_ADAPTER', 'STORAGE_ADAPTER'])(
    'rejects %s=fake when NODE_ENV=production',
    (key) => {
      const production = { ...base, NODE_ENV: 'production' };

      expect(() => loadEnv({ ...production, [key]: 'fake' })).toThrow(
        `Must not be fake when NODE_ENV=production\n  → at ${key}`,
      );
    },
  );

  it('accepts none and the real adapters when NODE_ENV=production', () => {
    const production = { ...base, NODE_ENV: 'production' };

    expect(loadEnv(production)).toMatchObject({ PUSH_ADAPTER: 'none', STORAGE_ADAPTER: 'none' });
    expect(
      loadEnv({
        ...production,
        PUSH_ADAPTER: 'fcm',
        STORAGE_ADAPTER: 'firebase',
        FIREBASE_STORAGE_BUCKET: 'demo-template.appspot.com',
      }),
    ).toMatchObject({ PUSH_ADAPTER: 'fcm', STORAGE_ADAPTER: 'firebase' });
  });

  it.each([
    ['PUSH_ADAPTER', 'firebase'],
    ['PUSH_ADAPTER', ''],
    ['STORAGE_ADAPTER', 's3'],
    ['STORAGE_ADAPTER', 'FAKE'],
  ])('rejects %s=%j', (key, value) => {
    expect(() => loadEnv({ ...base, [key]: value })).toThrow(new RegExp(key));
  });

  it('requires FIREBASE_STORAGE_BUCKET when STORAGE_ADAPTER=firebase', () => {
    expect(() => loadEnv({ ...base, STORAGE_ADAPTER: 'firebase' })).toThrow(
      /FIREBASE_STORAGE_BUCKET/,
    );
    expect(() => loadEnv({ ...base, STORAGE_ADAPTER: 'fake' })).not.toThrow();
  });

  it('accepts FIREBASE_STORAGE_EMULATOR_HOST as host:port', () => {
    expect(
      loadEnv({ ...base, FIREBASE_STORAGE_EMULATOR_HOST: 'localhost:9199' })
        .FIREBASE_STORAGE_EMULATOR_HOST,
    ).toBe('localhost:9199');
    expect(() =>
      loadEnv({ ...base, FIREBASE_STORAGE_EMULATOR_HOST: 'http://localhost:9199' }),
    ).toThrow(/FIREBASE_STORAGE_EMULATOR_HOST/);
  });

  it('parses RUN_WORKER as a boolean, false when unset', () => {
    expect(loadEnv(base).RUN_WORKER).toBe(false);
    expect(loadEnv({ ...base, RUN_WORKER: 'true' }).RUN_WORKER).toBe(true);
    expect(loadEnv({ ...base, RUN_WORKER: 'false' }).RUN_WORKER).toBe(false);
  });

  it.each(['1', 'yes', 'TRUE', ''])('rejects RUN_WORKER=%j', (value) => {
    expect(() => loadEnv({ ...base, RUN_WORKER: value })).toThrow(/RUN_WORKER/);
  });

  it('coerces PORT from a string', () => {
    expect(loadEnv({ ...base, PORT: '8080' }).PORT).toBe(8080);
  });

  it('splits CORS_ORIGINS on commas, trims, and normalizes to origins', () => {
    const env = loadEnv({
      ...base,
      CORS_ORIGINS: ' http://localhost:8081 , https://app.example.com/ ,',
    });

    expect(env.CORS_ORIGINS).toEqual(['http://localhost:8081', 'https://app.example.com']);
  });

  it('throws EnvError naming a missing required variable', () => {
    expect(() => loadEnv({})).toThrow(EnvError);
    expect(() => loadEnv({})).toThrow(/CORS_ORIGINS/);
    expect(() => loadEnv({})).toThrow(/DATABASE_URL/);
    expect(() => loadEnv({})).toThrow(/FIREBASE_PROJECT_ID/);
  });

  it('throws naming every invalid variable', () => {
    const invalid = {
      CORS_ORIGINS: 'not-a-url',
      PORT: '70000',
      LOG_LEVEL: 'loud',
      DATABASE_URL: 'mysql://localhost/x',
    };

    let message = '';
    try {
      loadEnv(invalid);
    } catch (err) {
      message = (err as Error).message;
    }
    expect(message).toContain('CORS_ORIGINS');
    expect(message).toContain('PORT');
    expect(message).toContain('LOG_LEVEL');
    expect(message).toContain('DATABASE_URL');
  });

  it('accepts FIREBASE_AUTH_EMULATOR_HOST as host:port', () => {
    expect(
      loadEnv({ ...base, FIREBASE_AUTH_EMULATOR_HOST: 'localhost:9099' })
        .FIREBASE_AUTH_EMULATOR_HOST,
    ).toBe('localhost:9099');
    expect(
      loadEnv({ ...base, FIREBASE_AUTH_EMULATOR_HOST: 'firebase-auth:9099' })
        .FIREBASE_AUTH_EMULATOR_HOST,
    ).toBe('firebase-auth:9099');
  });

  it.each(['http://localhost:9099', 'localhost', 'localhost:port'])(
    'rejects FIREBASE_AUTH_EMULATOR_HOST=%s',
    (value) => {
      expect(() => loadEnv({ ...base, FIREBASE_AUTH_EMULATOR_HOST: value })).toThrow(
        /FIREBASE_AUTH_EMULATOR_HOST/,
      );
    },
  );

  it('rejects FIREBASE_STORAGE_EMULATOR_HOST when NODE_ENV=production', () => {
    expect(() =>
      loadEnv({
        ...base,
        NODE_ENV: 'production',
        FIREBASE_STORAGE_EMULATOR_HOST: 'localhost:9199',
      }),
    ).toThrow(/FIREBASE_STORAGE_EMULATOR_HOST/);
  });

  it('rejects FIREBASE_AUTH_EMULATOR_HOST when NODE_ENV=production', () => {
    const production = { ...base, NODE_ENV: 'production' };

    expect(loadEnv(production).FIREBASE_AUTH_EMULATOR_HOST).toBeUndefined();
    expect(() => loadEnv({ ...production, FIREBASE_AUTH_EMULATOR_HOST: 'localhost:9099' })).toThrow(
      /FIREBASE_AUTH_EMULATOR_HOST/,
    );
  });

  it('rejects an empty CORS_ORIGINS list', () => {
    expect(() => loadEnv({ ...base, CORS_ORIGINS: ' , ' })).toThrow(/CORS_ORIGINS/);
  });
});

describe('loadDatabaseUrl', () => {
  it('reads only DATABASE_URL, without the other server variables', () => {
    expect(loadDatabaseUrl({ DATABASE_URL })).toBe(DATABASE_URL);
    expect(loadDatabaseUrl({ DATABASE_URL: 'postgresql://u:p@db:5432/app' })).toBe(
      'postgresql://u:p@db:5432/app',
    );
  });

  it('throws EnvError naming DATABASE_URL when missing or not a postgres URL', () => {
    expect(() => loadDatabaseUrl({})).toThrow(EnvError);
    expect(() => loadDatabaseUrl({})).toThrow(/DATABASE_URL/);
    expect(() => loadDatabaseUrl({ DATABASE_URL: 'http://localhost:5432/x' })).toThrow(
      /DATABASE_URL/,
    );
  });
});
