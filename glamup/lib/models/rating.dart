class Rating {
  final int? id;
  int productId;
  int orderId;
  int userId;
  final int rating;
  final String? review;
  final String? createdAt;
  final String? userName;
  final String? orderDate;

  Rating({
    this.id,
    this.productId = 0,
    this.orderId = 0,
    this.userId = 0,
    required this.rating,
    this.review,
    this.createdAt,
    this.userName,
    this.orderDate,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      productId: json['product_id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      rating: json['rating'] ?? 0,
      review: json['review'],
      createdAt: json['created_at'],
      userName: json['user_name'],
      orderDate: json['order_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'order_id': orderId,
      'user_id': userId,
      'rating': rating,
      'review': review,
    };
  }

  static List<Rating> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Rating.fromJson(json)).toList();
  }
}

class RatableProduct {
  final int productId;
  final String name;
  final String imageUrl;
  final double price;
  final int orderId;
  final String orderDate;

  RatableProduct({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.orderId,
    required this.orderDate,
  });

  factory RatableProduct.fromJson(Map<String, dynamic> json) {
    return RatableProduct(
      productId: json['product_id'],
      name: json['name'],
      imageUrl: json['image_url'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      orderId: json['order_id'],
      orderDate: json['order_date'],
    );
  }

  static List<RatableProduct> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => RatableProduct.fromJson(json)).toList();
  }
}

class RatedProduct {
  final int productId;
  final String name;
  final String imageUrl;
  final double price;
  final int ratingId;
  final int rating;
  final String? review;
  final String ratingDate;
  final int orderId;
  final String orderDate;

  RatedProduct({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.ratingId,
    required this.rating,
    this.review,
    required this.ratingDate,
    required this.orderId,
    required this.orderDate,
  });

  factory RatedProduct.fromJson(Map<String, dynamic> json) {
    return RatedProduct(
      productId: json['product_id'],
      name: json['name'],
      imageUrl: json['image_url'],
      price: json['price'].toDouble(),
      ratingId: json['rating_id'],
      rating: json['rating'],
      review: json['review'],
      ratingDate: json['rating_date'],
      orderId: json['order_id'],
      orderDate: json['order_date'],
    );
  }

  static List<RatedProduct> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => RatedProduct.fromJson(json)).toList();
  }
}
