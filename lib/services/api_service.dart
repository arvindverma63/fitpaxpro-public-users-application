import 'dart:convert';
import 'package:http/http.dart' as http;import '../models/banner_model.dart';

import '../models/category_model.dart';
import '../models/gym_model.dart';
import '../models/plan_model.dart';

class ApiService {
  // Set up the Base URL
  static const String baseUrl = 'https://chocolate-viper-895188.hostingersite.com/api/user-app';

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

  Future<bool> sendOtp(String name, String email, String phone) async {
    final url = Uri.parse('$baseUrl/registration/step-1');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('OTP Preview: ${data['data']['otp_preview']}'); // Keep for debugging
      return true;
    }
    throw Exception('Failed to send OTP. Please check your details.');
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/registration/verify-otp');
    final response = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return response.statusCode == 200;
  }

  Future<bool> submitPhysicalAttributes(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/registration/step-2');
    final response = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<bool> submitGoalsAndLifestyle(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/registration/step-3');
    final response = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<bool> submitMedicalIntel(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/registration/step-4');
    final response = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<bool> submitVisualAssets(String? imagePath, bool isPublic) async {
    final url = Uri.parse('$baseUrl/registration/step-5');
    var request = http.MultipartRequest('POST', url);
    request.fields['is_public'] = isPublic.toString();

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('profile_image', imagePath));
    }

    final response = await request.send();
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

  // // 1. Fetch All Gyms (Paginated response)
  // Future<List<Gym>> fetchGyms() async {
  //   final url = Uri.parse('$baseUrl/gyms');
  //   try {
  //     final response = await http.get(url, headers: {'accept': '*/*'});
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
  //       if (jsonResponse['success'] == true) {
  //         // Notice: data -> data (because of pagination)
  //         final List<dynamic> data = jsonResponse['data']['data'];
  //         return data.map((json) => Gym.fromJson(json)).toList();
  //       }
  //     }
  //     throw Exception('Failed to load gyms');
  //   } catch (e) {
  //     throw Exception('Network error: $e');
  //   }
  // }

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
}