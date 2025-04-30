import 'package:flutter/material.dart';
import 'package:glamup/controllers/wishlist_controller.dart';
import 'package:glamup/controllers/cart_controller.dart';
import 'package:glamup/models/wishlist.dart';
import 'package:glamup/services/api_service.dart';
import 'package:glamup/views/components/shared_header.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final WishlistController _wishlistController = WishlistController(apiService: ApiService());
  final CartController _cartController = CartController(apiService: ApiService());
  List<WishlistItem> wishlistItems = [];
  bool isLoading = true;
  bool isAddingToCart = false;
  
  @override
  void initState() {
    super.initState();
    loadWishlistItems();
  }
  
  Future<void> loadWishlistItems() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final items = await _wishlistController.getWishlistItems();
      
      if (mounted) {
        setState(() {
          wishlistItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wishlist: $e')),
        );
      }
    }
  }

  Future<void> removeFromWishlist(int productId) async {
    try {
      await _wishlistController.removeFromWishlist(productId);
      
      setState(() {
        wishlistItems.removeWhere((item) => item.productId == productId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from wishlist')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item: $e')),
      );
    }
  }

  Future<void> addToCart(int productId) async {
    try {
      setState(() {
        isAddingToCart = true;
      });
      
      await _cartController.addCartItem(productId, 1);
      
      setState(() {
        isAddingToCart = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item added to cart'),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isAddingToCart = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SharedHeader(
            title: 'Glam Wishlist',
            expandable: true,
            subtitle: 'Your favorite beauty products',
            onRefresh: loadWishlistItems,
          ),
          
          SliverToBoxAdapter(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (wishlistItems.isEmpty) {
      return _buildEmptyWishlist();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${wishlistItems.length} items',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add All to Cart'),
                onPressed: () => _addAllToCart(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...wishlistItems.map((item) => _buildWishlistItem(item)).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _addAllToCart() async {
    if (wishlistItems.isEmpty) return;
    
    try {
      setState(() {
        isAddingToCart = true;
      });
      
      // Add all items one by one
      for (final item in wishlistItems) {
        await _cartController.addCartItem(item.productId, 1);
      }
      
      setState(() {
        isAddingToCart = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${wishlistItems.length} items to cart'),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isAddingToCart = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add all items to cart: $e')),
      );
    }
  }

  Widget _buildEmptyWishlist() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.pink.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your wishlist is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Save items you love to your wishlist so you can easily find them later',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Explore Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/products');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistItem(WishlistItem item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${item.price}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => removeFromWishlist(item.productId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        color: Theme.of(context).primaryColor,
                        onPressed: () => addToCart(item.productId),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}