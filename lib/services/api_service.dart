import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;import '../models/banner_model.dart';

import '../models/category_model.dart';
import '../models/gym_model.dart';
import '../models/plan_model.dart';
import '../models/video_model.dart';
import '../models/comment_model.dart';

class ApiService {
  // Set up the Base URL
  static const String baseUrl = 'https://chocolate-viper-895188.hostingersite.com/api/user-app';
// Helper to build headers with an optional token
  Map<String, String> _headers([String? token]) {
    return {
      'Content-Type': 'application/json',
      'accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  Future<List<Gym>> fetchGyms() async {
    final url = Uri.parse('$baseUrl/gyms');

    try {
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
          // 'X-CSRF-TOKEN': 'your_token_here_if_needed',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data']['data'];
          return data.map((json) => Gym.fromJson(json)).toList();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load gyms. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Gym> fetchGymDetails(String gymId) async {
    final url = Uri.parse('$baseUrl/gyms/$gymId');

    try {
      final response = await http.get(url, headers: {'accept': '*/*'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          return Gym.fromJson(jsonResponse['data']);
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load gym details.');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Plan>> fetchGymPlans(String gymId) async {
    final url = Uri.parse('$baseUrl/gyms/$gymId/plans');

    try {
      final response = await http.get(url, headers: {'accept': '*/*'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Plan.fromJson(json)).toList();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load plans.');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> sendOtp(String name, String email, String phone) async {
    final url = Uri.parse('$baseUrl/registration/step-1');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Return the 'data' portion so the UI can see 'otp_preview'
        if (responseData['success'] == true) {
          return responseData['data'];
        }
      }

      // If we reach here, something went wrong with the data logic
      return null;
    } catch (e) {
      debugPrint('Step 1 Network Error: $e');
      return null;
    }
  }



  Future<String?> verifyOtp(String email, String otp) async {
    // NOTE: Check if your Login verification uses a different URL (like /auth/verify-otp)
    // Right now, this hits the registration endpoint.
    final url = Uri.parse('$baseUrl/registration/verify-otp');

    debugPrint('🌐 [API] Verifying OTP for: $email | Code: $otp');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Some servers expect OTP as an integer, some as a string.
        // We send it as a string here. If the server throws a 422, we might need int.parse(otp)
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      debugPrint('🌐 [API] Verify OTP Status Code: ${response.statusCode}');
      debugPrint('🌐 [API] Verify OTP Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Check for success safely
        if (data['success'] == true || data['success'] == 'true') {
          // Try getting token from root first, then fallback to data['token'] just in case
          final String? token = data['token']?.toString() ?? data['data']?['token']?.toString();

          if (token != null) {
            debugPrint('✅ [API] Token successfully extracted!');
            return token;
          } else {
            debugPrint('⚠️ [API] Success was true, but NO TOKEN was found in the response.');
          }
        } else {
          debugPrint('❌ [API] Server returned success: false. Message: ${data['message']}');
        }
      } else {
        debugPrint('❌ [API] Server rejected request. Status: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('🚨 [API] Verify OTP Crash: $e');
      return null;
    }
  }


  // --- UPDATED STEP 2 ---
  Future<bool> submitPhysicalAttributes(Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$baseUrl/registration/step-2');
    final response = await http.post(
      url,
      headers: _headers(token), // Pass the token here
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // --- UPDATED STEP 3 ---
  Future<bool> submitGoalsAndLifestyle(Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$baseUrl/registration/step-3');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }
// --- FETCH USER PROFILE ---
  Future<Map<String, dynamic>?> fetchUserProfile(String token) async {
    final url = Uri.parse('$baseUrl/auth/me');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // <-- CRITICAL: Sends the token
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          return jsonResponse['data']; // Returns { "first_name": "akash", "profile_image": null }
        }
      } else {
        debugPrint('Profile Fetch Failed: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('Profile Fetch Error: $e');
      return null;
    }
  }
  // --- UPDATED STEP 4 ---
  Future<bool> submitMedicalIntel(Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$baseUrl/registration/step-4');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // --- UPDATED STEP 5 ---
  Future<bool> submitVisualAssets(String? imagePath, bool isPublic, String token) async {
    final url = Uri.parse('$baseUrl/registration/step-5');
    var request = http.MultipartRequest('POST', url);

    // Add Authorization header to multipart request
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
    });

    request.fields['is_public'] = isPublic ? "1" : "0";

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('profile_image', imagePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return response.statusCode == 200;
  }

  // --- LOGIN FLOW ---

  Future<bool> loginUser(String email) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        // Assuming the API sends an OTP or confirms the login initialization
        return true;
      } else {
        throw Exception('Login failed. Please check your email and try again.');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }


  // 2. Fetch Featured Gyms (Direct array response)
  Future<List<Gym>> fetchFeaturedGyms() async {
    final url = Uri.parse('$baseUrl/gyms/featured');
    try {
      final response = await http.get(url, headers: {'accept': '*/*'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          // Notice: data is a direct array here
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Gym.fromJson(json)).toList();
        }
      }
      throw Exception('Failed to load featured gyms');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 3. Fetch Promotional Banners
  Future<List<PromoBanner>> fetchBanners() async {
    final url = Uri.parse('$baseUrl/banners');
    try {
      final response = await http.get(url, headers: {'accept': '*/*'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => PromoBanner.fromJson(json)).toList();
        }
      }
      throw Exception('Failed to load banners');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  Future<List<GymCategory>> fetchCategories() async {
    final url = Uri.parse('$baseUrl/categories');

    try {
      final response = await http.get(
        url,
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => GymCategory.fromJson(json)).toList();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load categories. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<GymVideo>> fetchGymVideos(String gymId) async {
    final url = Uri.parse('$baseUrl/gym/videos?gym_id=$gymId');
    try {
      final response = await http.get(url, headers: {'accept': 'application/json'});
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        return data.map((json) => GymVideo.fromJson(json)).toList();
      }
      throw Exception('Failed to load videos');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> toggleLike(String mediaId) async {
    final url = Uri.parse('$baseUrl/gym/interaction/like');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'likeable_id': mediaId,
          'likeable_type': 'media' // or 'video', depending on your backend enum
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Like error: $e');
      return false;
    }
  }

  Future<List<VideoComment>> fetchComments(String mediaId) async {
    final url = Uri.parse('$baseUrl/gym/interaction/comments?commentable_id=$mediaId&commentable_type=media');
    try {
      final response = await http.get(url, headers: {'accept': 'application/json'});
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        return data.map((json) => VideoComment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Comment fetch error: $e');
      return [];
    }
  }

  Future<bool> addComment(String mediaId, String content) async {
    final url = Uri.parse('$baseUrl/gym/interaction/comment');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'commentable_id': mediaId,
          'commentable_type': 'media',
          'content': content
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Add comment error: $e');
      return false;
    }
  }

  // Fetch ALL videos globally for the video feed
  Future<List<GymVideo>> fetchAllVideos() async {
    final url = Uri.parse('$baseUrl/gym/videos'); // No gym_id filter
    try {
      final response = await http.get(url, headers: {'accept': 'application/json'});
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        return data.map((json) => GymVideo.fromJson(json)).toList();
      }
      throw Exception('Failed to load all videos');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }


}