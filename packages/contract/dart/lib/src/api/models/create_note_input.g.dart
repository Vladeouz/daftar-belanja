// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_note_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateNoteInput _$CreateNoteInputFromJson(Map<String, dynamic> json) =>
    CreateNoteInput(
      title: json['title'] as String,
      body: json['body'] as String?,
    );

Map<String, dynamic> _$CreateNoteInputToJson(CreateNoteInput instance) =>
    <String, dynamic>{'title': instance.title, 'body': ?instance.body};
