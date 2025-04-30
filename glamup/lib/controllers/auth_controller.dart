import 'package:glamup/models/user.dart';
import 'package:glamup/services/api_service.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class AuthController {
  final ApiService apiService;

  AuthController({required this.apiService});

  Future<User?> login(String email, String password) async {
    try {
      final response = await apiService.post('/auth.php', {
        'action': 'login',
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body)['data'];
      final token = data['token'];
      final user = User.fromJson(data['user']);

      // Save token to Hive
      var box = Hive.box('glamupAuthBox');
      await box.put('token', token);
      await box.put('user', user.toJson());

      return user;
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<User?> register(String name, String email, String password) async {
    return _registerUser('register', name, email, password);
  }

  Future<User?> registerVendor(String name, String email, String password,
      String businessName, String description) async {
    return _registerUser('registerVendor', name, email, password,
        businessName: businessName, description: description);
  }

  Future<User?> registerAdmin(
      String name, String email, String password) async {
    return _registerUser('registerAdmin', name, email, password);
  }

  Future<User?> _registerUser(
      String action, String name, String email, String password,
      {String? businessName, String? description}) async {
    try {
      final Map<String, dynamic> requestBody = {
        'action': action,
        'name': name,
        'email': email,
        'password': password,
      };

      if (businessName != null && description != null) {
        requestBody['business_name'] = businessName;
        requestBody['description'] = description;
      }

      final response = await apiService.post('/auth.php', requestBody);
      final responseData = jsonDecode(response.body);
      final data = responseData['data'];
      final token = data['token'];
      final user = User.fromJson(data['user']);

      // Save token to Hive
      var box = Hive.box('glamupAuthBox');
      await box.put('token', token);
      await box.put('user', user.toJson());

      return user;
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await apiService.post('/auth.php', {
        'action': 'forgotPassword',
        'email': email,
      });

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(responseData['message']);
      }
    } catch (e) {
      throw Exception('Failed to send forgot password email: $e');
    }
  }

  Future<bool> checkOTP(String email, String otp) async {
  try {
    final response = await apiService.post('/auth.php', {
      'action': 'checkOTP',
      'email': email,
      'otp': otp,
    });

    final data = json.decode(response.body);
    
    if (response.statusCode == 200) {
      return data['data']?['valid'] == true;
    } else {
      throw Exception(data['message'] ?? 'Failed to verify OTP');
    }
  } catch (e) {
    throw Exception('Failed to verify OTP: $e');
  }
}

  Future<void> changePassword(String email,String otp ,String newPassword) async {
    try {
      final response = await apiService.post('/auth.php', {
        'action': 'changePassword',
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      });

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(responseData['message']);
      }
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<User?> getLoggedInUser() async {
    var box = Hive.box('glamupAuthBox');
    var userJson = box.get('user');
    if (userJson != null) {
      return User.fromJson(Map<String, dynamic>.from(userJson));
    }
    return null;
  }

  //get token from hive
  Future<String?> getToken() async {
    var box = Hive.box('glamupAuthBox');
    var token = box.get('token');
    return token;
  }

  // is vendor
  static isCurrentUserVendor() {
    var box = Hive.box('glamupAuthBox');
    var userJson = box.get('user');
    if (userJson != null && userJson['role'] != null) {
      return userJson['role'] == 'vendor';
    }
    return false;
  }

  Future<void> logout() async {
    var box = Hive.box('glamupAuthBox');
    await box.clear();
  }
}
