// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotePage _$NotePageFromJson(Map<String, dynamic> json) => NotePage(
  items: (json['items'] as List<dynamic>)
      .map((e) => Note.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$NotePageToJson(NotePage instance) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
};
