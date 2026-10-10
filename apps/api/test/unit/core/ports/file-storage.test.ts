import { describe, expect, it } from 'vitest';
import {
  assertValidFilePath,
  InvalidFilePathError,
} from '../../../../src/core/ports/file-storage.js';

describe('assertValidFilePath', () => {
  it.each([
    'a.txt',
    'users/123/avatar.png',
    'notes/2026-10-04/file name (1).pdf',
    'a/.hidden',
    'a/b..c',
  ])('accepts %j', (path) => {
    expect(() => assertValidFilePath(path)).not.toThrow();
  });

  it.each([
    '',
    '/a.txt',
    'a/',
    'a//b',
    '.',
    '..',
    'a/./b',
    'a/../b',
    '../a',
    'a\\b',
    'a\nb',
    'a\u0000b',
    'a\u007fb',
    'x'.repeat(1025),
  ])('rejects %j', (path) => {
    expect(() => assertValidFilePath(path)).toThrow(InvalidFilePathError);
  });

  it('names the path in the error message', () => {
    expect(() => assertValidFilePath('../a')).toThrow('Invalid file path: "../a"');
  });
});
