import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mengganti `debugPrint` selama satu test dan mengembalikan baris yang dicetak.
/// `debugPrint` asli dipulihkan lewat `addTearDown`.
List<String> captureDebugPrint() {
  final printed = <String>[];
  final original = debugPrint;
  debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
  addTearDown(() => debugPrint = original);
  return printed;
}
