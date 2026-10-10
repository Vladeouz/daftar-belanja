import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/entities/note_page.dart';

/// Note milik user yang login. Implementasi: `ApiNoteRepository`.
///
/// Note milik user lain atau yang sudah dihapus → `Err` dengan `FailureCode.notFound`.
/// Input yang ditolak API → `FailureCode.validation` dengan `fieldErrors` per field.
abstract interface class NoteRepository {
  /// [cursor] dari `NotePage.nextCursor` halaman sebelumnya; [limit] `null` = bawaan API (20).
  Future<Result<NotePage>> list({String? cursor, int? limit});

  Future<Result<Note>> get(String id);

  /// [body] `null` = tidak dikirim (API menyimpan `''`).
  Future<Result<Note>> create({required String title, String? body});

  /// Field `null` tidak diubah. API menolak bila keduanya `null` (`fieldErrors['_root']`).
  Future<Result<Note>> update(String id, {String? title, String? body});

  Future<Result<void>> delete(String id);
}
