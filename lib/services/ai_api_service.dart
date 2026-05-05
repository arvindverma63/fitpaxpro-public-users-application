import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_models.dart';

class AiApiService {
  static const String baseUrl = 'http://192.168.1.16:8000';
  static const String localAiUrl = 'http://192.168.1.17:1234/api/v1';

  Future<ChatResponse?> sendMessage(
      ChatRequest request, {
        String? imageBase64,
        List<Map<String, dynamic>>? history,
      }) async {
    final url = Uri.parse('$localAiUrl/chat');

    String finalPromptText = request.message;

    if (history != null && history.isNotEmpty) {
      String historyText = "Here is the recent chat history for context:\n";
      final recentHistory = history.length > 4 ? history.sublist(history.length - 4) : history;

      for (var msg in recentHistory) {
        String role = msg['isUser'] == true ? "User" : "AI";
        String text = msg['text'] ?? '';
        if (text.length > 300) text = '${text.substring(0, 300)}... [Truncated]';
        historyText += "$role: $text\n";
      }
      finalPromptText = "$historyText\nNow, respond to this new message from the User: ${request.message}";
    }

    dynamic inputPayload;

    if (imageBase64 != null && imageBase64.isNotEmpty) {
      inputPayload = [
        {
          "type": "text",
          "content": finalPromptText
        },
        {
          "type": "image",
          "data_url": "data:image/jpeg;base64,$imageBase64"
        }
      ];
    } else {
      inputPayload = [
        {
          "type": "text",
          "content": finalPromptText
        }
      ];
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "model": "google/gemma-4-e2b",
          "input": inputPayload,
          "context_length": 8000,
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiReply = "Sorry, I couldn't process the response.";

        if (data['output'] != null && data['output'] is List) {
          for (var item in data['output']) {
            if (item['type'] == 'message') {
              aiReply = item['content'] ?? '';
              break;
            }
          }
        }

        aiReply = _cleanAiResponse(aiReply);

        return ChatResponse(
          ok: true,
          kind: 'chat',
          reply: aiReply,
          exerciseExamples: null,
          nutritionExamples: null,
          suggestions: null,
        );
      } else {
        debugPrint('❌ [Local AI] Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('🚨 [Local AI] Network Error: $e');
      return null;
    }
  }

  String _cleanAiResponse(String text) {
    String cleanedText = text;
    cleanedText = cleanedText.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
    cleanedText = cleanedText.replaceAll(RegExp(r'Thinking Process:.*?(?=\n\n|\Z)', dotAll: true), '');
    cleanedText = cleanedText.replaceAll(RegExp(r'```thought.```', dotAll: true), '');
        return cleanedText.trim();
    }

  Future<Map<String, dynamic>?> generatePlan(String sessionId) async {
    final url = Uri.parse('$baseUrl/recommend');
    debugPrint('🏋️‍♂️ [AI Plan] Requesting plan for: $sessionId');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"session_id": sessionId}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [AI Plan] Plan generated successfully!');
        return jsonDecode(response.body);
      } else {
        debugPrint('❌ [AI Plan] Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('🚨 [AI Plan] Network Error: $e');
      return null;
    }
  }

  Future<bool> syncUserProfile(String sessionId, Map<String, dynamic> profileData) async {
    final url = Uri.parse('$baseUrl/profile/$sessionId');
    debugPrint('🔄 [AI Sync] Syncing profile for: $sessionId');

    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(profileData));
      if (response.statusCode == 200) {
        debugPrint('✅ [AI Sync] Profile updated in AI memory.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('🚨 [AI Sync] Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String sessionId) async {
    final url = Uri.parse('$baseUrl/profile/$sessionId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      debugPrint('🚨 [AI Profile] Fetch Error: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getChatHistory(String sessionId) async {
    final url = Uri.parse('$baseUrl/history/$sessionId');
    debugPrint('📜 [AI History] Fetching history for: $sessionId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        debugPrint('✅ [AI History] History loaded!');
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('🚨 [AI History] Error: $e');
      return null;
    }
  }

  Future<List<dynamic>?> searchExercises({String? query, String? muscle, int limit = 20}) async {
    String urlString = '$baseUrl/exercises?limit=$limit';
    if (query != null && query.isNotEmpty) urlString += '&q=$query';
    if (muscle != null && muscle.isNotEmpty) urlString += '&muscle=$muscle';

    final url = Uri.parse(urlString);
    debugPrint('🔍 [AI Search] Searching exercises: $urlString');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      debugPrint('🚨 [AI Search] Exercise Error: $e');
      return null;
    }
  }

  Future<List<dynamic>?> searchNutrition(String query, {int limit = 20}) async {
    final url = Uri.parse('$baseUrl/nutrition?q=$query&limit=$limit');
    debugPrint('🍎 [AI Search] Searching nutrition: $query');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      debugPrint('🚨 [AI Search] Nutrition Error: $e');
      return null;
    }
  }
}