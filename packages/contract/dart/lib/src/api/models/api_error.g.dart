// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => ApiError(
  code: ErrorCode.fromJson(json['code'] as String),
  message: json['message'] as String,
  details: (json['details'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(
      k,
      (e as List<dynamic>)
          .map((e) => ErrorIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  ),
);

Map<String, dynamic> _$ApiErrorToJson(ApiError instance) => <String, dynamic>{
  'code': _$ErrorCodeEnumMap[instance.code]!,
  'message': instance.message,
  'details': ?instance.details,
};

const _$ErrorCodeEnumMap = {
  ErrorCode.badRequest: 'BAD_REQUEST',
  ErrorCode.unauthenticated: 'UNAUTHENTICATED',
  ErrorCode.forbidden: 'FORBIDDEN',
  ErrorCode.notFound: 'NOT_FOUND',
  ErrorCode.conflict: 'CONFLICT',
  ErrorCode.validationError: 'VALIDATION_ERROR',
  ErrorCode.internalError: 'INTERNAL_ERROR',
  ErrorCode.$unknown: r'$unknown',
};
