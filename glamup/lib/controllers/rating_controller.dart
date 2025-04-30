import 'dart:convert';
import 'package:glamup/services/api_service.dart';
import 'package:glamup/models/rating.dart';

class RatingController {
  final ApiService apiService;

  RatingController({required this.apiService});

  // Add a rating for a product
  Future<Map<String, dynamic>> addRating(int productId, int orderId, int rating, {String? review}) async {
    try {
      final response = await apiService.post('/ratings.php', {
        'product_id': productId,
        'order_id': orderId,
        'rating': rating,
        'review': review,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to add rating');
      }

      final data = jsonDecode(response.body)['data'];
      return {
        'productId': data['product_id'],
        'avgRating': data['avg_rating'],
        'ratingCount': data['rating_count'],
      };
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }

  // Update an existing rating
  Future<Map<String, dynamic>> updateRating(int ratingId, int rating, {String? review}) async {
    try {
      final response = await apiService.put('/ratings.php', {
        'id': ratingId,
        'rating': rating,
        'review': review,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update rating');
      }

      final data = jsonDecode(response.body)['data'];
      return {
        'productId': data['product_id'],
        'avgRating': data['avg_rating'],
        'ratingCount': data['rating_count'],
      };
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }

  // Delete a rating
  Future<Map<String, dynamic>> deleteRating(int ratingId) async {
    try {
      final response = await apiService.delete('/ratings.php', {
        'id': ratingId,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to delete rating');
      }

      final data = jsonDecode(response.body)['data'];
      return {
        'productId': data['product_id'],
        'avgRating': data['avg_rating'],
        'ratingCount': data['rating_count'],
      };
    } catch (e) {
      throw Exception('Failed to delete rating: $e');
    }
  }

  // Get all ratings for a product
  Future<Map<String, dynamic>> getProductRatings(int productId) async {
    try {
      final response = await apiService.get('/ratings.php?product_id=$productId');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get product ratings');
      }

      final data = jsonDecode(response.body)['data'];
      return {
        'ratings': Rating.fromJsonList(data['ratings']),
        'avgRating': data['avg_rating'],
        'ratingCount': data['rating_count'],
      };
    } catch (e) {
      throw Exception('Failed to get product ratings: $e');
    }
  }

  // Check if a user can rate a specific product
  Future<Map<String, dynamic>> checkCanRateProduct(int productId) async {
    try {
      final response = await apiService.get('/ratings.php?product_id=$productId&check_can_rate=1');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to check rating eligibility');
      }

      final data = jsonDecode(response.body)['data'];
      return {
        'canRate': data['can_rate'],
        'ratableOrders': data['ratable_orders'],
        'existingRatings': data['existing_ratings'],
      };
    } catch (e) {
      throw Exception('Failed to check rating eligibility: $e');
    }
  }

  // Get all products that a user can rate
  Future<Map<String, dynamic>> getUserRatableProducts() async {
    try {
      final response = await apiService.get('/ratings.php?get_ratable_products=1');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get ratable products');
      }

      final data = jsonDecode(response.body)['data'];
      return {
        'ratableProducts': RatableProduct.fromJsonList(data['ratable_products']),
        'ratedProducts': RatedProduct.fromJsonList(data['rated_products']),
      };
    } catch (e) {
      throw Exception('Failed to get ratable products: $e');
    }
  }

  // Get all ratings by a user
  Future<List<Rating>> getUserRatings(int userId) async {
    try {
      final response = await apiService.get('/ratings.php?user_id=$userId');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get user ratings');
      }

      final data = jsonDecode(response.body)['data'];
      return Rating.fromJsonList(data);
    } catch (e) {
      throw Exception('Failed to get user ratings: $e');
    }
  }

  // Get all ratings for an order
  Future<List<Rating>> getOrderRatings(int orderId) async {
    try {
      final response = await apiService.get('/ratings.php?order_id=$orderId');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get order ratings');
      }

      final data = jsonDecode(response.body)['data'];
      return Rating.fromJsonList(data);
    } catch (e) {
      throw Exception('Failed to get order ratings: $e');
    }
  }
}