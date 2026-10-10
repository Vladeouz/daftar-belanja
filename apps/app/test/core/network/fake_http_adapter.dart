import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adapter HTTP palsu untuk dio: mencatat setiap request dan menjawab lewat [respond].
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Respons JSON dengan [status].
ResponseBody jsonResponse(Object? body, int status) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// Body error standar PRD bagian 5.
Map<String, Object?> errorBody(
  String code, {
  Map<String, Object?>? details,
}) => {
  'error': {'code': code, 'message': 'message for $code', 'details': ?details},
};
