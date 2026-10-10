// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error_code.dart';
import 'error_issue.dart';

part 'api_error.g.dart';

@JsonSerializable()
class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    this.details,
  });
  
  factory ApiError.fromJson(Map<String, Object?> json) => _$ApiErrorFromJson(json);
  
  final ErrorCode code;
  final String message;
  @JsonKey(includeIfNull: false)
  final Map<String, List<ErrorIssue>>? details;

  Map<String, Object?> toJson() => _$ApiErrorToJson(this);
}
