import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A minimal [HttpClientAdapter] test double: records every request it
/// receives and delegates the actual response to a handler the test
/// supplies, so tests can simulate arbitrary server behaviour (success,
/// 401, sequencing) without touching a real socket.
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponseBody(String jsonBody, int statusCode) {
  return ResponseBody.fromString(
    jsonBody,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
