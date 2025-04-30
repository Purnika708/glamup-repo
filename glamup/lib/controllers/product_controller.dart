import 'package:glamup/services/api_service.dart';
import 'package:glamup/models/product.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ProductController {
  final ApiService apiService;

  ProductController({required this.apiService});

  Future<List<Product>> getProducts() async {
    try {
      final response = await apiService.get('/products.php');
      final data = jsonDecode(response.body)['data'];
      return (data as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<Product?> getProduct(int id) async {
    try {
      final response = await apiService.get('/products.php?id=$id');
      final data = jsonDecode(response.body)['data'];
      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  Future<List<Product>> getProductsByVendor(int vendorId) async {
    try {
      final response = await apiService.get('/products.php?vendor_id=$vendorId');
      final data = jsonDecode(response.body)['data'];
      return (data as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products by vendor: $e');
    }
  }

  Future<void> addProduct(
      String name, String description, double price, int stock, int categoryId, int vendorId, String imageUrl) async {
    try {
      final response = await apiService.post('/products.php', {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'category_id': categoryId,
        'vendor_id': vendorId,
        'image_url': imageUrl,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to add product');
      }
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> addProductMultipart({
    int id = 0,
    required String name,
    required String description,
    required double price,
    required int stock,
    required int categoryId,
    required int vendorId,
    required File imageFile,
    required String token,
    bool isUpdate = false,
  }) async {
    try {
      var uri = Uri.parse('${apiService.baseUrl}/products.php');
      var request = http.MultipartRequest('POST', uri);

      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();
      request.fields['category_id'] = categoryId.toString();
      request.fields['vendor_id'] = vendorId.toString();
      request.fields['action'] = isUpdate ? 'update' : 'add';
      if (isUpdate) {
        request.fields['id'] = id.toString();
      }

      request.headers['Authorization'] = 'Bearer $token';

      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'product_image',
        imageStream,
        imageLength,
        filename: path.basename(imageFile.path),
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to add product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(int id, String name, String description, double price, int stock, int categoryId, int vendorId, String imageUrl) async {
    try {
      final response = await apiService.put('/products.php', {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'category_id': categoryId,
        'vendor_id': vendorId,
        'image_url': imageUrl,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> updateStock({required int id, required int stock}) async {
    try {
      final response = await apiService.patch('/products.php', {
        'action': 'update_stock',
        'id': id,
        'stock': stock,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update stock');
      }
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final response = await apiService.delete('/products.php?id=$id', {});

      if (response.statusCode != 200) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}