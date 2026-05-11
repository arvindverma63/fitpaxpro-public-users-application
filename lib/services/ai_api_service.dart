import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_models.dart';
import 'api_service.dart';

class AiApiService {
  static const String defaultBaseUrl = 'http://192.168.1.16:8000';
  static const String defaultLocalAiUrl = 'http://192.168.0.16:1234/api/v1';

  static String baseUrl = defaultBaseUrl;
  static String localAiUrl = defaultLocalAiUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('ai_base_url') ?? defaultBaseUrl;
    localAiUrl = prefs.getString('ai_local_url') ?? defaultLocalAiUrl;
  }

  Future<Map<String, String>> _getUrls() async {
    return {
      'baseUrl': baseUrl,
      'localAiUrl': localAiUrl,
    };
  }

  Future<ChatResponse?> sendMessage(
      ChatRequest request, {
        String? imageBase64,
        List<Map<String, dynamic>>? history,
      }) async {
    final urls = await _getUrls();
    final url = Uri.parse('${urls['localAiUrl']}/chat');

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

  // Helper to extract JSON from AI response if it contains extra text
  Map<String, dynamic>? _extractJson(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) {
        final jsonPart = text.substring(start, end + 1);
        return jsonDecode(jsonPart);
      }
    } catch (e) {
      debugPrint('⚠️ [AI Plan] JSON extraction failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> generatePlan(String sessionId) async {
    debugPrint('🏋️‍♂️ [AI Plan] Fetching Live Profile for Structured AI Generation...');
    
    try {
      // 1. Fetch live profile data
      final profileData = await ApiService().getFullProfile();
      if (profileData == null) {
        debugPrint('❌ [AI Plan] Could not fetch profile data');
        return null;
      }

      final profile = profileData['profile'] ?? {};
      
      // 2. Construct a prompt requesting STRICT JSON
      final String prompt = """
Generate a personalized fitness and nutrition plan for a user with the following profile:
- Goal: ${profile['goal_type'] ?? 'General fitness'}
- Diet: ${profile['diet_type'] ?? 'Balanced'}
- Gender: ${profile['gender'] ?? 'Not specified'}
- Weight: ${profile['current_weight'] ?? 'N/A'} kg
- Height: ${profile['height'] ?? 'N/A'} cm

YOU MUST RESPOND ONLY WITH A VALID JSON OBJECT. NO MARKDOWN, NO EXPLANATION.
The JSON must follow this exact structure:
{
  "reply": "A concise overview and motivation for the user.",
  "exercises": [
    {"name": "Exercise Name", "muscles": "Muscles", "instruction": "Step-by-step guidance"}
  ],
  "nutrition": [
    {"name": "Food Item", "calories": "Value", "protein": "Value", "carbohydrate": "Value", "fat": "Value"}
  ],
  "suggestions": ["Tip 1", "Tip 2"]
}
""";

      debugPrint('🏋️‍♂️ [AI Plan] Requesting Structured AI Plan...');

      // 3. Use the local AI
      final aiResponse = await sendMessage(
        ChatRequest(message: prompt, sessionId: sessionId),
      );

      if (aiResponse != null && aiResponse.ok) {
        // Try to parse the JSON
        final structuredData = _extractJson(aiResponse.reply);
        
        if (structuredData != null) {
          debugPrint('✅ [AI Plan] AI successfully generated structured JSON!');
          return {
            "ok": true,
            "reply": structuredData['reply'] ?? aiResponse.reply,
            "weekly_guidance": "Personalized based on your goals.",
            "meal_guidance": "Tailored to your ${profile['diet_type']} diet.",
            "exercises": structuredData['exercises'] ?? [],
            "nutrition": structuredData['nutrition'] ?? [],
            "suggestions": structuredData['suggestions'] ?? ["Stay hydrated", "Track sleep"]
          };
        } else {
          debugPrint('⚠️ [AI Plan] AI response was not JSON, falling back to text.');
          return {
            "ok": true,
            "reply": aiResponse.reply,
            "weekly_guidance": "General guidance based on your profile.",
            "meal_guidance": "General diet recommendations.",
            "exercises": [], 
            "nutrition": [],
            "suggestions": ["Try again for a structured plan"]
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('🚨 [AI Plan] Error in structured plan generation: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getChatHistory(String sessionId) async {
    final urls = await _getUrls();
    final url = Uri.parse('${urls['baseUrl']}/history/$sessionId');
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
    final urls = await _getUrls();
    String urlString = '${urls['baseUrl']}/exercises?limit=$limit';
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
    final urls = await _getUrls();
    final url = Uri.parse('${urls['baseUrl']}/nutrition?q=$query&limit=$limit');
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