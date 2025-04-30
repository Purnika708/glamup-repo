import 'dart:convert';
import 'package:glamup/models/rating.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  int stock;
  final int categoryId;
  int vendorId;
  final String imageUrl;
  final String createdAt;
  final String categoryName;
  final String categoryDescription;
  String vendorName;
  final int discount;
  final double avgRating;
  final int ratingCount;
  final List<Rating> recentRatings;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.vendorId = 0,
    required this.imageUrl,
    required this.createdAt,
    required this.categoryName,
    required this.categoryDescription,
    required this.vendorName,
    this.discount = 0,
    this.avgRating = 0.0,
    this.ratingCount = 0,
    this.recentRatings = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<Rating> recentRatings = [];
    if (json['recent_ratings'] != null) {
      recentRatings = Rating.fromJsonList(json['recent_ratings']);
    }

    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      stock: json['stock'],
      categoryId: json['category_id'],
      vendorId: json['vendor_id'] ?? 0,
      imageUrl: json['image_url'],
      createdAt: json['created_at'],
      categoryName: json['category_name'],
      categoryDescription: json['category_description'] ?? '',
      vendorName: json['vendor_name'],
      discount: json['discount'] ?? 0,
      avgRating: double.parse((json['avg_rating'] ?? 0).toString()),
      ratingCount: (json['rating_count'] ?? 0) is int ? json['rating_count'] : int.parse(json['rating_count'].toString()),
      recentRatings: recentRatings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'vendor_id': vendorId,
      'image_url': imageUrl,
      'created_at': createdAt,
      'category_name': categoryName,
      'category_description': categoryDescription,
      'vendor_name': vendorName,
      'discount': discount,
      'avg_rating': avgRating,
      'rating_count': ratingCount,
      'recent_ratings': recentRatings.map((rating) => rating.toJson()).toList(),
    };
  }

  static List<Product> fromJsonList(String jsonString) {
    final List<dynamic> data = jsonDecode(jsonString);
    return data.map((json) => Product.fromJson(json)).toList();
  }
}