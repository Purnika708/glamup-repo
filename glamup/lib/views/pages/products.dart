import 'package:flutter/material.dart';
import 'package:glamup/controllers/category_controller.dart';
import 'package:glamup/controllers/product_controller.dart';
import 'package:glamup/models/category.dart';
import 'package:glamup/models/product.dart';
import 'package:glamup/services/api_service.dart';
import 'package:glamup/views/components/product_card.dart';
import 'package:glamup/views/components/category_card.dart';
import 'package:glamup/controllers/cart_controller.dart';
import 'package:glamup/controllers/wishlist_controller.dart';
import 'package:glamup/controllers/auth_controller.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late ProductController productController;
  late CategoryController categoryController;
  late CartController cartController;
  late WishlistController wishlistController;
  late AuthController authController;

  List<Product> allProducts = [];
  List<Product> displayedProducts = [];
  List<Category> categories = [];
  Set<int> favoriteProductIds = {};
  bool isLoading = true;
  bool isUserLoggedIn = false;
  int? selectedCategoryId;
  String searchQuery = "";

  // Price range filter
  RangeValues _priceRange = const RangeValues(0, 5000);
  double _minPrice = 0;
  double _maxPrice = 5000;
  bool _showFilters = false;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final apiService = ApiService();
    productController = ProductController(apiService: apiService);
    categoryController = CategoryController(apiService: apiService);
    cartController = CartController(apiService: apiService);
    wishlistController = WishlistController(apiService: apiService);
    authController = AuthController(apiService: apiService);

    _checkLoginStatus();
    fetchData();
    _loadWishlistItems();
  }

  Future<void> _checkLoginStatus() async {
    final user = await authController.getLoggedInUser();
    setState(() {
      isUserLoggedIn = user != null;
    });
  }

  Future<void> _loadWishlistItems() async {
    try {
      final wishlistItems = await wishlistController.getWishlistItems();
      setState(() {
        favoriteProductIds =
            wishlistItems.map((item) => item.productId).toSet();
      });
    } catch (e) {
      print("Error loading wishlist: $e");
    }
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final fetchedProducts = await productController.getProducts();
      final fetchedCategories = await categoryController.getCategories();

      // Find min and max prices from products
      if (fetchedProducts.isNotEmpty) {
        _minPrice = fetchedProducts
            .map((p) => p.price)
            .reduce((min, price) => price < min ? price : min);
        _maxPrice = fetchedProducts
            .map((p) => p.price)
            .reduce((max, price) => price > max ? price : max);

        // Add some padding to max price
        _maxPrice = (_maxPrice * 1.1).roundToDouble();
        _priceRange = RangeValues(_minPrice, _maxPrice);
      }

      setState(() {
        allProducts = fetchedProducts;
        displayedProducts = fetchedProducts;
        categories = fetchedCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
    }
  }

  void filterProducts() {
    List<Product> filtered = allProducts;

    // Apply category filter if selected
    if (selectedCategoryId != null) {
      filtered =
          filtered
              .where((product) => product.categoryId == selectedCategoryId)
              .toList();
    }

    // Apply price range filter
    filtered =
        filtered
            .where(
              (product) =>
                  product.price >= _priceRange.start &&
                  product.price <= _priceRange.end,
            )
            .toList();

    // Apply search filter if query exists
    if (searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (product) =>
                    product.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    product.description.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    product.categoryName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    product.vendorName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    setState(() {
      displayedProducts = filtered;
    });
  }

  void _resetFilters() {
    setState(() {
      selectedCategoryId = null;
      searchQuery = '';
      searchController.clear();
      _priceRange = RangeValues(_minPrice, _maxPrice);
    });
    filterProducts();
  }

  Future<void> _addToCart(Product product) async {
    if (!isUserLoggedIn) {
      _showLoginRequiredDialog('Add to Cart');
      return;
    }

    try {
      await cartController.addCartItem(product.id, 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().split(':').last.trim())),
      );
    }
  }

  Future<void> _toggleFavorite(int productId) async {
    if (!isUserLoggedIn) {
      _showLoginRequiredDialog('Add to Wishlist');
      return;
    }

    final product = allProducts.firstWhere((p) => p.id == productId);
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
        await wishlistController.removeFromWishlist(productId);
      } else {
        await wishlistController.addToWishlist(product);
      }

      // Show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyFavorite ? 'Removed from wishlist' : 'Added to wishlist',
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
      builder:
          (context) => AlertDialog(
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
    bool hasActiveFilters =
        selectedCategoryId != null ||
        searchQuery.isNotEmpty ||
        _priceRange.start > _minPrice ||
        _priceRange.end < _maxPrice;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Products",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            tooltip: 'Toggle filters',
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh products',
            onPressed: fetchData,
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Colors.pink.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: const BorderSide(),
                        ),
                        suffixIcon:
                            searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                    filterProducts();
                                  },
                                )
                                : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                        filterProducts();
                      },
                    ),
                  ),

                  // Price Range Slider (visible when _showFilters is true)
                  if (_showFilters)
                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Price Range",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Rs. ${_priceRange.start.toInt()}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Rs. ${_priceRange.end.toInt()}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            RangeSlider(
                              values: _priceRange,
                              min: _minPrice,
                              max: _maxPrice,
                              divisions: 100,
                              labels: RangeLabels(
                                "Rs.${_priceRange.start.toInt()}",
                                "Rs.${_priceRange.end.toInt()}",
                              ),
                              onChanged: (RangeValues values) {
                                setState(() {
                                  _priceRange = values;
                                });
                              },
                              onChangeEnd: (RangeValues values) {
                                filterProducts();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Categories Horizontal List
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return CategoryCard(
                          category: categories[index],
                          isSelected:
                              selectedCategoryId == categories[index].id,
                          onTap: () {
                            setState(() {
                              if (selectedCategoryId == categories[index].id) {
                                selectedCategoryId =
                                    null; // Deselect if tapped again
                              } else {
                                selectedCategoryId = categories[index].id;
                              }
                            });
                            filterProducts();
                          },
                        );
                      },
                    ),
                  ),

                  // Results count and reset filters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${displayedProducts.length} products',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (hasActiveFilters)
                          TextButton.icon(
                            icon: const Icon(Icons.filter_list_off),
                            label: const Text('Clear filters'),
                            onPressed: _resetFilters,
                          ),
                      ],
                    ),
                  ),

                  // Products Grid
                  Expanded(
                    child:
                        displayedProducts.isEmpty
                            ? const Center(
                              child: Text('No products match your filters'),
                            )
                            : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio:
                                        0.6, // Changed from 0.7 to 0.6 to allow more vertical space
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: displayedProducts.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: displayedProducts[index],
                                  isFavorite: favoriteProductIds.contains(
                                    displayedProducts[index].id,
                                  ),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/product-details',
                                      arguments: displayedProducts[index].id,
                                    );
                                  },
                                  onAddToCart:
                                      () =>
                                          _addToCart(displayedProducts[index]),
                                  onFavoriteToggle:
                                      () => _toggleFavorite(
                                        displayedProducts[index].id,
                                      ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
