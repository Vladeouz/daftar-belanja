// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });
  
  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
  
  final String id;
  @JsonKey(includeIfNull: true)
  final String? email;
  @JsonKey(includeIfNull: true)
  final String? displayName;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$UserToJson(this);
}
