import 'package:glamup/services/api_service.dart';
import 'package:glamup/models/category.dart';
import 'dart:convert';

class CategoryController {
  final ApiService apiService;

  CategoryController({required this.apiService});

  Future<List<Category>> getCategories() async {
    try {
      final response = await apiService.get('/categories.php');
      final data = jsonDecode(response.body)['data'];
      return (data as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<Category?> getCategory(int id) async {
    try {
      final response = await apiService.get('/categories.php?id=$id');
      final data = jsonDecode(response.body)['data'];
      return Category.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  Future<void> addCategory(String name, String description) async {
    try {
      final response = await apiService.post('/categories.php', {
        'name': name,
        'description': description,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to add category');
      }
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> updateCategory(int id, String name, String description) async {
    try {
      final response = await apiService.put('/categories.php', {
        'id': id,
        'name': name,
        'description': description,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update category');
      }
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Future<void> deleteCategory(int id) async {
  //   try {
  //     final response = await apiService.delete('/categories.php', {
  //       'id': id,
  //     });

  //     if (response.statusCode != 200) {
  //       throw Exception('Failed to delete category');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to delete category: $e');
  //   }
  // }
}
