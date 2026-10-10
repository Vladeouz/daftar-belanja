// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'system/system_client.dart';
import 'users/users_client.dart';
import 'notes/notes_client.dart';

/// API `v1`
class ApiClient {
  ApiClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1';

  SystemClient? _system;
  UsersClient? _users;
  NotesClient? _notes;

  SystemClient get system => _system ??= SystemClient(_dio, baseUrl: _baseUrl);

  UsersClient get users => _users ??= UsersClient(_dio, baseUrl: _baseUrl);

  NotesClient get notes => _notes ??= NotesClient(_dio, baseUrl: _baseUrl);
}
