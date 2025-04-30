import 'dart:convert';
import 'package:glamup/models/address.dart';
import 'package:glamup/services/api_service.dart';

class AddressController {
  final ApiService apiService;

  AddressController({required this.apiService});

  Future<List<Address>> getAddresses() async {
    try {
      final response = await apiService.get('/address.php');
      final data = jsonDecode(response.body)['data'];
      return (data as List).map((item) => Address.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  Future<Address> getAddress(int id) async {
    try {
      final response = await apiService.get('/address.php?id=$id');
      final data = jsonDecode(response.body)['data'];
      return Address.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch address: $e');
    }
  }

  Future<void> addAddress(String fullName, String phone, String addressLine, 
      String city, String state, String zipCode, String country) async {
    try {
      final response = await apiService.post('/address.php', {
        'full_name': fullName,
        'phone': phone,
        'address_line': addressLine,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'country': country,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to add address');
      }
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  Future<void> updateAddress(int id, String fullName, String phone, String addressLine, 
      String city, String state, String zipCode, String country) async {
    try {
      final response = await apiService.put('/address.php', {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'address_line': addressLine,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'country': country,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update address');
      }
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      final response = await apiService.delete('/address.php?id=$id', {});

      if (response.statusCode != 200) {
        throw Exception('Failed to delete address');
      }
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }
}