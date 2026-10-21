import 'dart:convert';
import 'package:http/http.dart' as http;

class SaynApiClient {
  final String baseUrl;
  String? authToken;

  SaynApiClient({this.baseUrl = 'https://sayn-api-worker.allanmaazimdad.workers.dev'});

  Future<Map<String, dynamic>> refineText({
    required String text,
    required String mode,
    String? tone,
    String? targetLanguage,
    String? customInstruction,
    int? synonymIntensity,
    List<String>? freezeWords,
    bool? includeAlternatives,
    bool? includeGrammarIssues,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/ai/refine');
    final headers = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode({
      'text': text,
      'mode': mode,
      if (tone != null) 'tone': tone,
      if (targetLanguage != null) 'targetLanguage': targetLanguage,
      if (customInstruction != null) 'customInstruction': customInstruction,
      if (synonymIntensity != null) 'synonymLevel': synonymIntensity,
      if (freezeWords != null && freezeWords.isNotEmpty) 'freezeWords': freezeWords,
      if (includeAlternatives != null) 'includeAlternatives': includeAlternatives,
      if (includeGrammarIssues != null) 'includeGrammarIssues': includeGrammarIssues,
    });

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      String msg = 'Refinement failed (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error']?['message'] != null) {
          msg = errJson['error']['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> detectAi(String text) async {
    final uri = Uri.parse('$baseUrl/api/v1/ai/detect');
    final headers = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode({'text': text});
    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      String msg = 'AI detection failed (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error']?['message'] != null) {
          msg = errJson['error']['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> generateCitation({
    required String sourceTextOrUrl,
    String style = 'apa',
    String? sourceType,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/ai/citation');
    final headers = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode({
      'sourceTextOrUrl': sourceTextOrUrl,
      'style': style,
      if (sourceType != null) 'sourceType': sourceType,
    });
    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      String msg = 'Citation generation failed (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error']?['message'] != null) {
          msg = errJson['error']['message'];
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
