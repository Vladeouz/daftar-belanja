import 'package:app/core/error/failure.dart';
import 'package:app/core/error/result.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/entities/note_page.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';

/// [NoteRepository] dalam memori yang meniru API notes: terbaru lebih dulu, pagination
/// cursor (bawaan 20 per halaman), `NOT_FOUND` untuk id tak dikenal, dan `VALIDATION_ERROR`
/// untuk judul kosong atau ubah tanpa field.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({int initialCount = 0}) {
    for (var i = 1; i <= initialCount; i++) {
      _insert(title: 'Catatan $i', body: 'Isi $i');
    }
  }

  /// Tersimpan, terlama lebih dulu.
  final List<Note> _notes = [];
  var _clock = DateTime.utc(2026, 10);
  var _nextId = 1;

  /// `true` = setiap operasi gagal seperti API tidak bisa dihubungi.
  bool offline = false;

  List<Note> get notes => _notes.reversed.toList();

  @override
  Future<Result<NotePage>> list({String? cursor, int? limit}) async {
    if (offline) return _networkDown();
    final newestFirst = notes;
    final start = cursor == null
        ? 0
        : newestFirst.indexWhere((n) => n.id == cursor) + 1;
    final size = limit ?? 20;
    final items = newestFirst.skip(start).take(size).toList();
    final hasMore = start + items.length < newestFirst.length;
    return Ok(
      NotePage(items: items, nextCursor: hasMore ? items.last.id : null),
    );
  }

  @override
  Future<Result<Note>> get(String id) async {
    if (offline) return _networkDown();
    final index = _indexOf(id);
    return index == -1 ? _notFound() : Ok(_notes[index]);
  }

  @override
  Future<Result<Note>> create({required String title, String? body}) async {
    if (offline) return _networkDown();
    if (title.trim().isEmpty) return _titleTooSmall();
    return Ok(_insert(title: title.trim(), body: body ?? ''));
  }

  @override
  Future<Result<Note>> update(String id, {String? title, String? body}) async {
    if (offline) return _networkDown();
    if (title == null && body == null) {
      return const Err(
        Failure(
          FailureCode.validation,
          fieldErrors: {
            '_root': [FieldIssue('custom', 'At least one field is required')],
          },
        ),
      );
    }
    if (title != null && title.trim().isEmpty) return _titleTooSmall();
    final index = _indexOf(id);
    if (index == -1) return _notFound();
    final old = _notes[index];
    final updated = Note(
      id: old.id,
      title: title?.trim() ?? old.title,
      body: body ?? old.body,
      createdAt: old.createdAt,
      updatedAt: _tick(),
    );
    _notes[index] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (offline) return _networkDown();
    final index = _indexOf(id);
    if (index == -1) return _notFound();
    _notes.removeAt(index);
    return const Ok(null);
  }

  Note _insert({required String title, required String body}) {
    final now = _tick();
    final note = Note(
      id: 'note-${_nextId++}',
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
    );
    _notes.add(note);
    return note;
  }

  DateTime _tick() => _clock = _clock.add(const Duration(minutes: 1));

  int _indexOf(String id) => _notes.indexWhere((n) => n.id == id);

  static Err<T> _networkDown<T>() => Err(const Failure(FailureCode.network));

  static Err<T> _notFound<T>() =>
      Err(const Failure(FailureCode.notFound, message: 'Note not found'));

  static Err<T> _titleTooSmall<T>() => Err(
    const Failure(
      FailureCode.validation,
      fieldErrors: {
        'title': [FieldIssue('too_small', 'Too small')],
      },
    ),
  );
}
