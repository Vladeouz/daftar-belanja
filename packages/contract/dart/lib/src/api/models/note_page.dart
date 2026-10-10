// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'note.dart';

part 'note_page.g.dart';

@JsonSerializable()
class NotePage {
  const NotePage({
    required this.items,
    required this.nextCursor,
  });
  
  factory NotePage.fromJson(Map<String, Object?> json) => _$NotePageFromJson(json);
  
  final List<Note> items;

  /// `null` di halaman terakhir
  @JsonKey(includeIfNull: true)
  final String? nextCursor;

  Map<String, Object?> toJson() => _$NotePageToJson(this);
}
