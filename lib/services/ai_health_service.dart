import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

class AiHealthStatus {
  final bool reachable;
  final int? version;
  final bool planSupported;
  final String? message;
  final String? rawSnippet;
  AiHealthStatus({required this.reachable, this.version, required this.planSupported, this.message, this.rawSnippet});
}

class AiHealthService {
  Future<AiHealthStatus> check() async {
    if (!kAiRemoteEnabled || kAiMilestoneEndpoint.isEmpty) {
      return AiHealthStatus(reachable: false, version: null, planSupported: false, message: 'Remote AI disabled', rawSnippet: null);
    }
    try {
      final resp = await http.get(Uri.parse(kAiMilestoneEndpoint));
      if (resp.statusCode != 200) {
        final body = resp.body;
        return AiHealthStatus(
          reachable: false,
          version: null,
          planSupported: false,
          message: 'HTTP ${resp.statusCode}',
          rawSnippet: body.isNotEmpty ? body.substring(0, body.length>140?140:body.length) : null,
        );
      }
      Map<String,dynamic> json;
      try {
        json = jsonDecode(resp.body) as Map<String,dynamic>;
      } catch (e) {
        return AiHealthStatus(
          reachable: false,
          version: null,
          planSupported: false,
          message: 'decode_error',
          rawSnippet: resp.body.substring(0, resp.body.length>160?160:resp.body.length),
        );
      }
      final v = json['version'] is int ? json['version'] as int : int.tryParse(json['version']?.toString() ?? '');
      // We consider plan support available at version >=4
      final planSupported = (v ?? 0) >= 4;
      return AiHealthStatus(
        reachable: true,
        version: v,
        planSupported: planSupported,
        message: json['message']?.toString(),
        rawSnippet: null,
      );
    } catch (e) {
      return AiHealthStatus(reachable: false, version: null, planSupported: false, message: e.toString(), rawSnippet: null);
    }
  }
}
