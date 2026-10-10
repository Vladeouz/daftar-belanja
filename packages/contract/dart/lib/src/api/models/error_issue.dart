// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'error_issue.g.dart';

@JsonSerializable()
class ErrorIssue {
  const ErrorIssue({
    required this.code,
    required this.message,
  });
  
  factory ErrorIssue.fromJson(Map<String, Object?> json) => _$ErrorIssueFromJson(json);
  
  final String code;
  final String message;

  Map<String, Object?> toJson() => _$ErrorIssueToJson(this);
}
