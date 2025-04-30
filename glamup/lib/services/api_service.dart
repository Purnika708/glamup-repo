import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class ApiService {
  String baseUrl = 'http://192.168.1.97/glamup/backend';

  ApiService();

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers(); 
    final response = await http.get(url, headers: headers);
    _handleResponse(response);
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.patch(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> delete(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.delete(
      url,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _handleResponse(response);
    return response;
  }

  // Method for verifying Khalti payment
  Future<Map<String, dynamic>> verifyKhaltiPayment({
    required String token,
    required String amount,
  }) async {
    final endpoint = '/verify-khalti-payment';
    final data = {'token': token, 'amount': amount};

    final response = await post(endpoint, data);
    return jsonDecode(response.body);
  }

  Future<Map<String, String>> _headers() async {
    var box = Hive.box('glamupAuthBox');
    String? token = box.get('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.toString()}',
    };
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.body.isNotEmpty) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message']);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    }

    if (response.body.isEmpty) {
      throw Exception('Failed to load data: Empty response');
    }
  }
}
