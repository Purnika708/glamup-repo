import 'dart:convert';
import 'package:glamup/models/cart.dart';
import 'package:glamup/services/api_service.dart';
import 'package:hive/hive.dart';

class CartController {
  final ApiService apiService;

  CartController({required this.apiService});

  bool isCurrentUserVendor() {
    var box = Hive.box('glamupAuthBox');
    var userJson = box.get('user');
    if (userJson != null && userJson['role'] != null) {
      return userJson['role'] == 'vendor';
    }
    return false;
  }

  Future<List<CartItem>> getCartItems() async {
    try {
      final response = await apiService.get('/cart.php');
      final data = jsonDecode(response.body)['data'];
      return (data as List).map((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch cart items${e is Exception ? ': ${e.toString().replaceFirst('Exception: ', '')}' : ': $e'}');
    }
  }

  Future<void> addCartItem(int productId, int quantity) async {
    if (isCurrentUserVendor()) {
      throw Exception('Vendors cannot add items to cart');
    }
    try {
      final response = await apiService.post('/cart.php', {
        'product_id': productId,
        'quantity': quantity,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to add item to cart');
      }
    } catch (e) {
      throw Exception('Failed to add item to cart${e is Exception ? ': ${e.toString().replaceFirst('Exception: ', '')}' : ': $e'}');
    }
  }

  Future<void> updateCartItem(int cartId, int productId, int quantity) async {
    try {
      final response = await apiService.put('/cart.php', {
        'id': cartId,
        'product_id': productId,
        'quantity': quantity,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update cart item');
      }
    } catch (e) {
      throw Exception('Failed to update cart item${e is Exception ? ': ${e.toString().replaceFirst('Exception: ', '')}' : ': $e'}');
    }
  }

  Future<void> deleteCartItem(int cartId) async {
    try {
      final response = await apiService.delete('/cart.php?id=$cartId', {
        'id': cartId,
      });
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete cart item');
      }
    } catch (e) {
      throw Exception('Failed to delete cart item${e is Exception ? ': ${e.toString().replaceFirst('Exception: ', '')}' : ': $e'}');
    }
  }

  Future<void> placeOrder(Map<String, dynamic> orderData) async {
    try {
      // Use the correct endpoint as shown in the PHP code
      final response = await apiService.post('/order.php', orderData);
      
      print(response.body); // Debugging line to check the response body
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to place order');
      }
    } catch (e) {
      throw Exception('Failed to place order: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}