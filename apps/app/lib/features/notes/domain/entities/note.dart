import 'package:equatable/equatable.dart';

/// Catatan milik user yang login (CONTOH; ditiru lalu dihapus di proyek).
class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  /// UUID dari API.
  final String id;

  /// 1–120 karakter, sudah dirapikan API.
  final String title;

  /// Boleh kosong, maksimal 5000 karakter.
  final String body;

  /// UTC.
  final DateTime createdAt;

  /// UTC.
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, title, body, createdAt, updatedAt];
}
