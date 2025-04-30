import 'package:flutter/material.dart';
import 'package:glamup/controllers/category_controller.dart';
import 'package:glamup/controllers/product_controller.dart';
import 'package:glamup/controllers/cart_controller.dart';
import 'package:glamup/controllers/auth_controller.dart';
import 'package:glamup/controllers/wishlist_controller.dart';
import 'package:glamup/controllers/vendor_controller.dart';
import 'package:glamup/models/category.dart';
import 'package:glamup/models/product.dart';
import 'package:glamup/models/vendor.dart';
import 'package:glamup/services/api_service.dart';
import 'package:glamup/views/components/product_card.dart';
import 'package:glamup/views/components/category_card.dart';
import 'package:glamup/views/components/shared_header.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final CategoryController _categoryController = CategoryController(apiService: ApiService());
  final ProductController _productController = ProductController(apiService: ApiService());
  final CartController _cartController = CartController(apiService: ApiService());
  final AuthController _authController = AuthController(apiService: ApiService());
  final WishlistController _wishlistController = WishlistController(apiService: ApiService());
  final VendorController _vendorController = VendorController(apiService: ApiService());
  final ScrollController _scrollController = ScrollController();

  List<Category> categories = [];
  List<Product> products = [];
  List<Vendor> vendors = [];
  Set<int> favoriteProductIds = {};
  bool isLoading = true;
  int? selectedCategoryId;
  String? errorMessage;
  bool isUserLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchData();
    _loadWishlistItems();
    _fetchVendors();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _fetchData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      final fetchedCategories = await _categoryController.getCategories();
      final fetchedProducts = await _productController.getProducts();

      setState(() {
        categories = fetchedCategories;
        products = fetchedProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print("Error fetching data: $e");
    }
  }

  Future<void> _fetchVendors() async {
    try {
      final fetchedVendors = await _vendorController.getVendors();
      setState(() {
        vendors = fetchedVendors;
      });
    } catch (e) {
      // Optionally handle vendor fetch error
    }
  }

  Future<void> _filterByCategory(int categoryId) async {
    try {
      setState(() {
        isLoading = true;
        selectedCategoryId = selectedCategoryId == categoryId ? null : categoryId;
      });
      
      List<Product> filteredProducts;
      if (selectedCategoryId == null) {
        filteredProducts = await _productController.getProducts();
      } else {
        filteredProducts = await _productController.getProducts();
        filteredProducts = filteredProducts.where((p) => p.categoryId == selectedCategoryId).toList();
      }

      setState(() {
        products = filteredProducts;
        isLoading = false;
      });

      // Scroll to product section
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          MediaQuery.of(context).size.height * 0.4,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      print("Error filtering data: $e");
    }
  }

  Future<void> _addToCart(Product product) async {
    if (!isUserLoggedIn) {
      _showLoginRequiredDialog('Add to Cart');
      return;
    }
    
    try {
      await _cartController.addCartItem(product.id, 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${product.name} added to cart'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
          backgroundColor: Theme.of(context).primaryColor,
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().split(':').last.trim()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        )
      );
    }
  }

  Future<void> _toggleFavorite(int productId) async {
    final product = products.firstWhere((p) => p.id == productId);
    final isCurrentlyFavorite = favoriteProductIds.contains(productId);
    
    setState(() {
      if (isCurrentlyFavorite) {
        favoriteProductIds.remove(productId);
      } else {
        favoriteProductIds.add(productId);
      }
    });
    
    try {
      if (isCurrentlyFavorite) {
        await _wishlistController.removeFromWishlist(productId);
      } else {
        await _wishlistController.addToWishlist(product);
      }
      
      // Show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyFavorite
                ? 'Removed from wishlist'
                : 'Added to wishlist',
            style: const TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isCurrentlyFavorite ? Colors.grey : Colors.pink,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // Revert the state if operation failed
      setState(() {
        if (isCurrentlyFavorite) {
          favoriteProductIds.add(productId);
        } else {
          favoriteProductIds.remove(productId);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update wishlist: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoginRequiredDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: Text('You need to be logged in to $action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('LOGIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchData();
          await _fetchVendors();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SharedHeader(
              title: "GlamUp Beauty",
              expandable: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.store_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/vendors');
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: isLoading
                ? _buildLoadingView()
                : errorMessage != null
                  ? _buildErrorView()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banner
                        _buildBanner(),
                        
                        // Categories Section
                        _buildSectionHeader("Categories", onSeeAllPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All categories coming soon!'),
                              behavior: SnackBarBehavior.floating,
                            )
                          );
                        }),
                        _buildCategoryList(),

                        // Vendors Section
                        _buildSectionHeader("Vendors", onSeeAllPressed: () {
                          Navigator.pushNamed(context, '/vendors');
                        }),
                        _buildVendorList(),
                        
                        // All Products Section
                        _buildSectionHeader(
                          selectedCategoryId != null 
                            ? categories.firstWhere((c) => c.id == selectedCategoryId).name
                            : "All Products",
                          subtitle: selectedCategoryId != null
                              ? "Tap a category again to reset filter"
                              : null,
                        ),
                      ],
                    ),
            ),
            
            // Products Grid
            isLoading
                ? const SliverToBoxAdapter(child: SizedBox(height: 300))
                : errorMessage != null
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : products.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            height: 300,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No products found!",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverMasonryGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return ProductCard(
                                product: product,
                                isFavorite: favoriteProductIds.contains(product.id),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/product-details',
                                    arguments: product.id,
                                  );
                                },
                                onAddToCart: () => _addToCart(product),
                                onFavoriteToggle: () => _toggleFavorite(product.id),
                              );
                            },
                          ),
                        ),
                      
            // Footer
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      "GlamUp - Beauty Products",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Glamup © 2025 All Rights Reserved",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner loading
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 180,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
          ),
        ),
        
        // Categories loading
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // All products loading
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'An unknown error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: const AssetImage('assets/images/makeup.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.pink.withOpacity(0.2),
                    Colors.purple.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Your Beauty Destination",
                  style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                    ),
                  ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Discover elegance, redefine beauty",
                  style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                    ),
                  ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/products');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Shop Now",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle, VoidCallback? onSeeAllPressed}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          if (onSeeAllPressed != null)
            TextButton(
              onPressed: onSeeAllPressed,
              child: Text(
                "See All",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryCard(
            category: categories[index],
            isSelected: selectedCategoryId == categories[index].id,
            onTap: () => _filterByCategory(categories[index].id),
          );
        },
      ),
    );
  }

  Widget _buildVendorList() {
    if (vendors.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No vendors available')),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: vendors.length,
        itemBuilder: (context, index) {
          final vendor = vendors[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/vendor-details', arguments: vendor.id);
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        vendor.businessName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vendor.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}