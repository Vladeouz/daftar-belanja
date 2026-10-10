import 'package:api_client/api_client.dart' as dto;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/notes/data/note_mapper.dart';
import 'package:app/features/notes/domain/entities/note_page.dart';

import '../mocks.dart';

void main() {
  test('noteFromDto memetakan semua field dengan timestamp UTC', () {
    final note = noteFromDto(dto.Note.fromJson(noteJson));

    expect(note, testNote);
    expect(note.createdAt.isUtc, isTrue);
    expect(note.updatedAt.isUtc, isTrue);
  });

  test('notePageFromDto memetakan items dan nextCursor', () {
    final page = notePageFromDto(
      dto.NotePage.fromJson({
        'items': [noteJson, noteJson],
        'nextCursor': 'c1',
      }),
    );

    expect(page, NotePage(items: [testNote, testNote], nextCursor: 'c1'));
  });

  test('halaman terakhir → nextCursor null, items tidak bisa diubah', () {
    final page = notePageFromDto(
      dto.NotePage.fromJson({'items': <Object?>[], 'nextCursor': null}),
    );

    expect(page.nextCursor, isNull);
    expect(page.hasMore, isFalse);
    expect(() => page.items.add(testNote), throwsUnsupportedError);
  });
}
