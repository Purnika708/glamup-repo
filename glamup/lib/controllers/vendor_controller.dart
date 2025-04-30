import 'dart:convert';
import 'package:glamup/models/vendor.dart';
import 'package:glamup/services/api_service.dart';

class VendorController {
  final ApiService apiService;

  VendorController({required this.apiService});

  Future<List<Vendor>> getVendors() async {
    try {
      final response = await apiService.get('/vendors.php');
      final data = jsonDecode(response.body)['data'];
      return (data as List).map((json) => Vendor.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vendors: $e');
    }
  }

  Future<Vendor?> getVendor(int id) async {
    try {
      final response = await apiService.get('/vendors.php?id=$id');
      final data = jsonDecode(response.body)['data'];
      return Vendor.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch vendor: $e');
    }
  }
}