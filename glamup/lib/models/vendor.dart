import 'dart:convert';
import 'package:glamup/models/product.dart';

class Vendor {
  final int id;
  final String businessName;
  final String description;
  final String createdAt;
  final String ownerName;
  final String? ownerEmail;
  final List<Product>? products;
  final int? productCount;

  Vendor({
    required this.id,
    required this.businessName,
    required this.description,
    required this.createdAt,
    required this.ownerName,
    this.ownerEmail,
    this.products,
    this.productCount,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    List<Product>? products;
    if (json.containsKey('products') && json['products'] != null) {
      products = (json['products'] as List)
          .map((item) => Product.fromJson(item))
          .toList();
    }

    return Vendor(
      id: json['id'],
      businessName: json['business_name'],
      description: json['description'],
      createdAt: json['created_at'],
      ownerName: json['owner_name'],
      ownerEmail: json['owner_email'],
      products: products,
      productCount: json['product_count'] ?? products?.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'description': description,
      'created_at': createdAt,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'products': products?.map((product) => product.toJson()).toList(),
      'product_count': productCount,
    };
  }

  static List<Vendor> fromJsonList(String jsonString) {
    final List<dynamic> data = jsonDecode(jsonString);
    return data.map((json) => Vendor.fromJson(json)).toList();
  }
}