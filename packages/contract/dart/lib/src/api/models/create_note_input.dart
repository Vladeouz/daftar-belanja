// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_note_input.g.dart';

@JsonSerializable()
class CreateNoteInput {
  const CreateNoteInput({
    required this.title,
    this.body,
  });
  
  factory CreateNoteInput.fromJson(Map<String, Object?> json) => _$CreateNoteInputFromJson(json);
  
  final String title;
  @JsonKey(includeIfNull: false)
  final String? body;

  Map<String, Object?> toJson() => _$CreateNoteInputToJson(this);
}
