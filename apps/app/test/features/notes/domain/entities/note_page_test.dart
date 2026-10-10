import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/notes/domain/entities/note_page.dart';

import '../../mocks.dart';

void main() {
  test('hasMore mengikuti nextCursor', () {
    expect(NotePage(items: [testNote], nextCursor: 'c1').hasMore, isTrue);
    expect(const NotePage(items: [], nextCursor: null).hasMore, isFalse);
  });

  test('sama bila isi dan cursor sama', () {
    expect(
      NotePage(items: [testNote], nextCursor: 'c1'),
      NotePage(items: [testNote], nextCursor: 'c1'),
    );
  });
}
