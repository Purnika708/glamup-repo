import 'dart:convert';

class Category {
  final int id;
  final String name;
  final String description;

  Category({required this.id, required this.name, required this.description});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  static List<Category> fromJsonList(String jsonString) {
    final List<dynamic> data = jsonDecode(jsonString);
    return data.map((json) => Category.fromJson(json)).toList();
  }
}
