import 'dart:convert';
import 'package:glamup/services/api_service.dart';

class ProfileController {
  final ApiService apiService;

  ProfileController({required this.apiService});

  Future<Map<String, dynamic>> getProfile({required String token}) async {
    try {
      final response = await apiService.get(
        '/profile.php',
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body['data'];
      } else {
        throw Exception(body['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String email,
    String? businessName,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'name': name,
        'email': email,
      };
      if (businessName != null) data['business_name'] = businessName;
      if (description != null) data['description'] = description;

      final response = await apiService.put(
        '/profile.php',
        data,
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body['data'];
      } else {
        throw Exception(body['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
