class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String productImage;
  final String productPrice;
  final int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.productPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productImage: json['product_image'],
      productPrice: json['product_price'],
      quantity: json['quantity'],
    );
  }
}
