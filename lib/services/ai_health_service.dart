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
      // Debug: capture raw body for diagnostics (trim to 220 chars)
      // (Remove or gate behind a debug flag for production if noisy.)
      if (resp.body.isNotEmpty) {
        // ignore: avoid_print
        print('[AiHealth] status=${resp.statusCode} raw=${resp.body.substring(0, resp.body.length>220?220:resp.body.length)}');
      }
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
      int? v = json['version'] is int ? json['version'] as int : int.tryParse(json['version']?.toString() ?? '');
      bool hasFlag = json.containsKey('planSupported');
      bool planSupported = hasFlag ? json['planSupported'] == true : (v ?? 0) >= 4;
      // Secondary heuristic: if version missing and flag missing but success message matches expected readiness string
      final msg = json['message']?.toString() ?? '';
      if (!planSupported && v == null && !hasFlag && msg.toLowerCase().contains('endpoint ready')) {
        planSupported = true;
        v = 4; // infer minimum
      }
      // If flag present but true and version null, infer version 4
      if (planSupported && v == null) v = 4;
      // Debug print parsed result
      // ignore: avoid_print
      print('[AiHealth] parsed keys=${json.keys.toList()} version=$v planSupported=$planSupported hasFlag=$hasFlag msg="$msg"');
      return AiHealthStatus(
        reachable: true,
        version: v,
        planSupported: planSupported,
        message: msg,
        rawSnippet: (v == null || !hasFlag) ? (resp.body.substring(0, resp.body.length>180?180:resp.body.length)) : null,
      );
    } catch (e) {
      return AiHealthStatus(reachable: false, version: null, planSupported: false, message: e.toString(), rawSnippet: null);
    }
  }
}
