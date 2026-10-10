// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'api_error.dart';

part 'error_body.g.dart';

@JsonSerializable()
class ErrorBody {
  const ErrorBody({
    required this.error,
  });
  
  factory ErrorBody.fromJson(Map<String, Object?> json) => _$ErrorBodyFromJson(json);
  
  final ApiError error;

  Map<String, Object?> toJson() => _$ErrorBodyToJson(this);
}
