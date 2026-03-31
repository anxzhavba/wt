import 'package:http/http.dart' as http;

class HttpService {
  final void Function(String) log;

  HttpService(this.log);

  Future<String> sendRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
  }) async {
    log('HTTP request: $method $uri');
    log('Headers: ${headers ?? {}}');
    if (body?.isNotEmpty ?? false) {
      log('Body: $body');
    }

    try {
      final request = http.Request(method, uri);
      request.headers.addAll(headers ?? {});
      if (body?.isNotEmpty ?? false) {
        request.body = body!;
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final payload = response.body;
      log('HTTP ${response.statusCode} ${response.reasonPhrase}');
      log('Response body length: ${payload.length}');
      return payload;
    } catch (error) {
      final errorMessage = 'HTTP error: $error';
      log(errorMessage);
      rethrow;
    }
  }
}
