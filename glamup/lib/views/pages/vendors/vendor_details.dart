import 'package:flutter/material.dart';
import 'package:glamup/controllers/vendor_controller.dart';
import 'package:glamup/controllers/wishlist_controller.dart';
import 'package:glamup/controllers/auth_controller.dart';
import 'package:glamup/models/product.dart';
import 'package:glamup/models/vendor.dart';
import 'package:glamup/services/api_service.dart';
import 'package:intl/intl.dart';

class VendorDetailsPage extends StatefulWidget {
  final int vendorId;

  const VendorDetailsPage({Key? key, required this.vendorId}) : super(key: key);

  @override
  _VendorDetailsPageState createState() => _VendorDetailsPageState();
}

class _VendorDetailsPageState extends State<VendorDetailsPage> {
  final VendorController _vendorController = VendorController(apiService: ApiService());
  final WishlistController _wishlistController = WishlistController(apiService: ApiService());
  final AuthController _authController = AuthController(apiService: ApiService());
  
  late Future<Vendor?> _vendorFuture;
  Set<int> favoriteProductIds = {};
  bool isUserLoggedIn = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _vendorFuture = _vendorController.getVendor(widget.vendorId);
    _checkLoginStatus();
    _loadWishlistItems();
  }
  
  Future<void> _checkLoginStatus() async {
    final user = await _authController.getLoggedInUser();
    setState(() {
      isUserLoggedIn = user != null;
    });
  }

  Future<void> _loadWishlistItems() async {
    try {
      final wishlistItems = await _wishlistController.getWishlistItems();
      setState(() {
        favoriteProductIds = wishlistItems.map((item) => item.productId).toSet();
      });
    } catch (e) {
      print("Error loading wishlist: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Vendor?>(
        future: _vendorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data == null) {
            return _buildErrorView('Vendor not found');
          }

          final vendor = snapshot.data!;
          return CustomScrollView(
            slivers: [
              _buildAppBar(vendor),
              SliverToBoxAdapter(child: _buildVendorInfo(vendor)),
              SliverToBoxAdapter(child: _buildDescription(vendor)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Products (${vendor.products?.length ?? vendor.productCount ?? 0})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (vendor.products != null && vendor.products!.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // Navigate to vendor products page
                            Navigator.pushNamed(
                              context,
                              '/products',
                              arguments: {'vendorId': vendor.id},
                            );
                          },
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                ),
              ),
              _buildProductsGrid(vendor),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Details'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading vendor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _vendorFuture = _vendorController.getVendor(widget.vendorId);
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Vendor vendor) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          vendor.businessName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      vendor.businessName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVendorInfo(Vendor vendor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shop Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.person,
                    title: 'Owner',
                    value: vendor.ownerName,
                  ),
                  if (vendor.ownerEmail != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.email,
                      title: 'Email',
                      value: vendor.ownerEmail!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.shopping_bag,
                    title: 'Products',
                    value: '${vendor.productCount ?? vendor.products?.length ?? 0}',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.date_range,
                    title: 'Since',
                    value: _formatDate(vendor.createdAt),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(Vendor vendor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vendor.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(Vendor vendor) {
    if (vendor.products == null || vendor.products!.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: const Text(
            'No products available from this vendor',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Use a vertical ListView with horizontal cards (like cart/orders)
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final Product product = vendor.products![index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/product-details',
                arguments: product.id,
              );
            },
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rs. ${(product.price - product.discount).toStringAsFixed(0)}",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (product.discount > 0)
                            Text(
                              "Rs. ${product.price.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                product.ratingCount > 0
                                  ? '${product.avgRating.toStringAsFixed(1)}/5'
                                  : 'Not rated',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (product.ratingCount > 0)
                                Text(
                                  ' (${product.ratingCount})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.vendorName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stock/Out of stock
                    if (product.stock <= 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: vendor.products!.length,
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}