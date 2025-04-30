import 'package:hive/hive.dart';
import 'package:glamup/models/product.dart';

part 'wishlist.g.dart';

@HiveType(typeId: 2)
class WishlistItem {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String imageUrl;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final double discount;

  @HiveField(5)
  final String vendorName;

  @HiveField(6)
  final int productId;

  WishlistItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.discount,
    required this.vendorName,
    required this.productId,
  });

  factory WishlistItem.fromProduct(Product product) {
    return WishlistItem(
      id: DateTime.now().millisecondsSinceEpoch,
      name: product.name,
      imageUrl: product.imageUrl,
      price: product.price,
      discount: product.discount.toDouble(),
      vendorName: product.vendorName,
      productId: product.id,
    );
  }
}