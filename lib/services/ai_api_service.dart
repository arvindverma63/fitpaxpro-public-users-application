import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_models.dart';

class AiApiService {
  // Your computer's local network IP
  static const String baseUrl = 'http://192.168.1.16:8000';

  // ==========================================
  // 1. CORE AI ENDPOINTS
  // ==========================================

  Future<ChatResponse?> sendMessage(ChatRequest request) async {
    final url = Uri.parse('$baseUrl/chat');
    debugPrint('🤖 [AI Chat] Sending message...');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [AI Chat] Success!');
        return ChatResponse.fromJson(jsonDecode(response.body));
      } else {
        debugPrint('❌ [AI Chat] Server Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('🚨 [AI Chat] Network Error: $e');
      return null;
    }
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

  // ==========================================
  // 2. USER MANAGEMENT & CONTEXT
  // ==========================================

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

  // ==========================================
  // 3. KNOWLEDGE SEARCH (Discover Tab)
  // ==========================================

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

  // ==========================================
  // 4. SYSTEM & MAINTENANCE
  // ==========================================

  Future<bool> checkHealth() async {
    final url = Uri.parse('$baseUrl/health');
    try {
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> submitFeedback(String rating, {String? name, String? reply, String? message}) async {
    final url = Uri.parse('$baseUrl/feedback');
    debugPrint('👍 [AI Feedback] Submitting: $rating');

    try {
      final body = {
        "rating": rating,
        if (name != null) "name": name,
        if (reply != null) "reply": reply,
        if (message != null) "message": message,
      };

      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 [AI Feedback] Error: $e');
      return false;
    }
  }

  Future<bool> retrainKnowledgeBase() async {
    final url = Uri.parse('$baseUrl/retrain');
    try {
      final response = await http.post(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}