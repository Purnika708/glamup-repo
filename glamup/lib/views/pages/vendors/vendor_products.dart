import 'package:flutter/material.dart';
import 'package:glamup/controllers/auth_controller.dart';
import 'package:glamup/controllers/product_controller.dart';
import 'package:glamup/models/product.dart';
import 'package:glamup/models/user.dart';
import 'package:glamup/services/api_service.dart';

class VendorProductsPage extends StatefulWidget {
  const VendorProductsPage({super.key});

  @override
  _VendorProductsPageState createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage> {
  final ProductController _productController = ProductController(apiService: ApiService());
  final AuthController _authController = AuthController(apiService: ApiService());
  
  bool isLoading = true;
  bool isDeleting = false;
  List<Product> products = [];
  User? currentUser;
  String? errorMessage;
  int? vendorId;
  
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  List<Product> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadVendorProducts();
  }

  Future<void> _loadVendorProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // First, get the current user to verify they're a vendor
      final user = await _authController.getLoggedInUser();
      if (user == null || user.role.toLowerCase() != 'vendor') {
        setState(() {
          errorMessage = 'Access denied: Only vendors can view their products';
          isLoading = false;
        });
        return;
      }
      
      // Store the current user
      currentUser = user;
      
      // Get the vendor's products using the new method
      final vendorProducts = await _productController.getProductsByVendor(user.vendorId as int);
      
      setState(() {
        products = vendorProducts;
        filteredProducts = vendorProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading products: $e';
        isLoading = false;
      });
    }
  }

  void _filterProducts() {
    if (searchQuery.isEmpty) {
      setState(() {
        filteredProducts = products;
      });
      return;
    }
    
    final query = searchQuery.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        return product.name.toLowerCase().contains(query) ||
               product.description.toLowerCase().contains(query) ||
               product.categoryName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteProduct(Product product) async {
    setState(() {
      isDeleting = true;
    });

    try {
      await _productController.deleteProduct(product.id);
      
      // Update the product list after deletion
      setState(() {
        products.removeWhere((p) => p.id == product.id);
        filteredProducts.removeWhere((p) => p.id == product.id);
        isDeleting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} deleted successfully')),
      );
    } catch (e) {
      setState(() {
        isDeleting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e')),
      );
    }
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateStockDialog(Product product) async {
    final TextEditingController stockController = TextEditingController(text: product.stock.toString());
    bool isSubmitting = false;
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Stock'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'New Stock',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final value = stockController.text.trim();
                          final int? newStock = int.tryParse(value);
                          if (newStock == null || newStock < 0) {
                            setState(() => errorMsg = 'Enter valid stock');
                            return;
                          }
                          setState(() => isSubmitting = true);
                          try {
                            await _productController.updateStock(
                              id: product.id,
                              stock: newStock,
                            );
                            setState(() {
                              product.stock = newStock;
                              isSubmitting = false;
                            });
                            if (mounted) Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Stock updated')),
                            );
                            _loadVendorProducts();
                          } catch (e) {
                            setState(() {
                              errorMsg = 'Failed: $e';
                              isSubmitting = false;
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorView()
              : _buildProductList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/vendor-add-product')
              .then((_) => _loadVendorProducts());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'An error occurred',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadVendorProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Products Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first product to start selling',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              onPressed: () {
                Navigator.pushNamed(context, '/vendor-add-product')
                    .then((_) => _loadVendorProducts());
              },
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          searchQuery = '';
                        });
                        _filterProducts();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
              _filterProducts();
            },
          ),
        ),
        
        // Products count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                '${filteredProducts.length} ${filteredProducts.length == 1 ? 'product' : 'products'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (searchQuery.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.filter_list_off),
                  label: const Text('Clear filter'),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                    _filterProducts();
                  },
                ),
            ],
          ),
        ),
        
        // Product list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/vendor-edit-product',
                      arguments: product.id,
                    ).then((_) => _loadVendorProducts());
                  },
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
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Product Details
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
                                'Category: ${product.categoryName}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rs. ${product.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: product.stock > 0
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      product.stock > 0
                                          ? 'In Stock (${product.stock})'
                                          : 'Out of Stock',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: product.stock > 0
                                            ? Colors.green[800]
                                            : Colors.red[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Actions
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/vendor-edit-product',
                                  arguments: product.id,
                                ).then((_) => _loadVendorProducts());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.inventory_2, color: Colors.orange),
                              tooltip: 'Update Stock',
                              onPressed: () => _showUpdateStockDialog(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(product),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}