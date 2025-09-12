import 'dart:convert';
import 'package:http/http.dart' as http;

class AiApiException implements Exception {
  final String code;
  final String? message;
  AiApiException(this.code, [this.message]);
  @override
  String toString() => 'AiApiException($code ${message ?? ''})';
}

class AiApiClient {
  final String baseUrl; // e.g. https://your-app.vercel.app/api/ai
  final String? groqDevKey; // optional dev key header
  final String? appSecret; // optional X-App-Secret
  final bool debug;

  AiApiClient({required this.baseUrl, this.groqDevKey, this.appSecret, this.debug = false});

  Future<Map<String,dynamic>> postType(String type, Map<String,dynamic> body) async {
    final uri = Uri.parse(baseUrl);
    final payload = { 'type': type, ...body };
    if (debug) {
      // ignore: avoid_print
      print('[AiApiClient] -> $type ${jsonEncode(payload).substring(0, payload.length>400?400:payload.length)}');
    }
    final headers = <String,String>{'Content-Type':'application/json'};
    if (groqDevKey!=null && groqDevKey!.isNotEmpty) headers['X-Groq-Key'] = groqDevKey!;
    if (appSecret!=null && appSecret!.isNotEmpty) headers['X-App-Secret'] = appSecret!;
    final resp = await http.post(uri, headers: headers, body: jsonEncode(payload));
    Map<String,dynamic>? decoded;
    try { decoded = jsonDecode(resp.body) as Map<String,dynamic>; } catch(_) {}
    if (resp.statusCode != 200) {
      final code = decoded?['error']?.toString() ?? 'http_${resp.statusCode}';
      throw AiApiException(code, decoded?['hint']?.toString() ?? decoded?['detail']?.toString());
    }
    if (debug) {
      // ignore: avoid_print
      print('[AiApiClient] <- $type status=${resp.statusCode} keys=${decoded?.keys.toList()}');
    }
    return decoded ?? <String,dynamic>{};
  }
}
