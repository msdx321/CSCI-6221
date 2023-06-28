import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final logger = Logger();
String openAIKey = "";

void main() async {
  var handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(_echoRequest);

  var server = await io.serve(handler, InternetAddress.loopbackIPv4, 8099);

  try {
    openAIKey = await File('config/api_key').readAsString();
  } catch (e) {
    logger.e('Failed to read API key from file: $e');
    return;
  }

  if (openAIKey.isEmpty) {
    logger.e('OpenAI key not found in api_key file.');
    return;
  }

  logger.i('Serving at http://${server.address.host}:${server.port}');
}

Future<Response> _echoRequest(Request request) async {
  final openAIUrl = Uri.parse('https://api.openai.com/v1/chat/completions');

  final body = await request.readAsString();

  Map<String, String> headers = {...request.headers};
  headers['authorization'] = 'Bearer $openAIKey';
  headers['host'] = openAIUrl.host;

  logger.i('Forwarding request to OpenAI with headers: $headers');
  var response = await http.post(
    openAIUrl,
    headers: headers,
    body: body,
  );

  if (response.statusCode == 200) {
    logger.i('Received successful response from OpenAI.');
  } else {
    logger.e(
        'Received error ${response.statusCode} from OpenAI: ${response.body}');
  }

  return Response(
    response.statusCode,
    body: response.body,
  );
}
