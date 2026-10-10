// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_note_input.g.dart';

@JsonSerializable()
class UpdateNoteInput {
  const UpdateNoteInput({
    this.title,
    this.body,
  });
  
  factory UpdateNoteInput.fromJson(Map<String, Object?> json) => _$UpdateNoteInputFromJson(json);
  
  @JsonKey(includeIfNull: false)
  final String? title;
  @JsonKey(includeIfNull: false)
  final String? body;

  Map<String, Object?> toJson() => _$UpdateNoteInputToJson(this);
}
