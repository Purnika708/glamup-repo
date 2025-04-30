import 'package:hive/hive.dart';
import 'package:glamup/models/wishlist.dart';
import 'package:glamup/models/product.dart';
import 'package:glamup/controllers/auth_controller.dart';
import 'package:glamup/services/api_service.dart';

class WishlistController {
  final String _localBoxName = 'wishlistBox';
  final ApiService apiService;
  final AuthController? authController;

  WishlistController({required this.apiService, this.authController});

  // Add item to wishlist
  Future<void> addToWishlist(Product product) async {
    final box = await Hive.openBox<WishlistItem>(_localBoxName);
    
    // Check if product already exists in wishlist
    final exists = box.values.any((item) => item.productId == product.id);
    if (exists) return;
    
    // Create wishlist item
    final wishlistItem = WishlistItem.fromProduct(product);
    
    // Store locally
    await box.put(wishlistItem.id.toString(), wishlistItem);
  }

  // Remove item from wishlist
  Future<void> removeFromWishlist(int productId) async {
    final box = await Hive.openBox<WishlistItem>(_localBoxName);
    
    // Find and remove the item
    final itemKey = box.keys.firstWhere(
      (key) => box.get(key)?.productId == productId,
      orElse: () => null
    );
    
    if (itemKey != null) {
      await box.delete(itemKey);
      
    }
  }

  // Check if item exists in wishlist
  Future<bool> isInWishlist(int productId) async {
    final box = await Hive.openBox<WishlistItem>(_localBoxName);
    return box.values.any((item) => item.productId == productId);
  }

  // Get all wishlist items
  Future<List<WishlistItem>> getWishlistItems() async {
    final box = await Hive.openBox<WishlistItem>(_localBoxName);
    return box.values.toList();
  }

  // Clear wishlist
  Future<void> clearWishlist() async {
    final box = await Hive.openBox<WishlistItem>(_localBoxName);
    await box.clear();
  }
}