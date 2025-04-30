import 'package:flutter/material.dart';
import 'package:glamup/controllers/product_controller.dart';
import 'package:glamup/controllers/category_controller.dart';
import 'package:glamup/controllers/auth_controller.dart';
import 'package:glamup/models/category.dart';
import 'package:glamup/services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_platform/universal_platform.dart';

class VendorAddProductPage extends StatefulWidget {
  const VendorAddProductPage({super.key});

  @override
  State<VendorAddProductPage> createState() => _VendorAddProductPageState();
}

class _VendorAddProductPageState extends State<VendorAddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductController _productController = ProductController(apiService: ApiService());
  final CategoryController _categoryController = CategoryController(apiService: ApiService());
  final AuthController _authController = AuthController(apiService: ApiService());

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  List<Category> _categories = [];
  Category? _selectedCategory;
  File? _selectedImage;
  int? _vendorId;
  String? _token;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndVendor();
  }

  Future<void> _fetchCategoriesAndVendor() async {
    try {
      final categories = await _categoryController.getCategories();
      final user = await _authController.getLoggedInUser();
      final token = await _authController.getToken();

      if (user == null || user.role.toLowerCase() != 'vendor') {
        setState(() {
          _errorMessage = "Only vendors can add products.";
        });
        return;
      }
      setState(() {
        _categories = categories;
        _selectedCategory = categories.isNotEmpty ? categories[0] : null;
        _vendorId = user.id;
        _token = token;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load categories or vendor info: $e";
      });
    }
  }

  Future<void> _pickImage() async {
    File? pickedFile;
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        pickedFile = File(picked.path);
      }
    } else {
      // Desktop: Windows, Linux, macOS
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        pickedFile = File(result.files.single.path!);
      }
    }
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null || _selectedImage == null || _vendorId == null || _token == null) {
      setState(() {
        _errorMessage = "Please fill all fields and select an image.";
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _productController.addProductMultipart(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        categoryId: _selectedCategory!.id,
        vendorId: _vendorId!,
        imageFile: _selectedImage!,
        token: _token!,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add product: $e';
        _isSubmitting = false;
      });
    }
    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 1,
      ),
      body: Stack(
        children: [
          _categories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Add New Product",
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                  ),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Product Name',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter product name' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descController,
                                  decoration: InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    prefixIcon: const Icon(Icons.description_outlined),
                                  ),
                                  maxLines: 2,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter description' : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _priceController,
                                        decoration: InputDecoration(
                                          labelText: 'Price',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          prefixIcon: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(width: 4),
                                            Text('Rs.', style: TextStyle(fontSize: 16)),
                                          ],
                                          ),
                                        ),
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'Enter price';
                                          final val = double.tryParse(v);
                                          if (val == null || val < 0) return 'Enter valid price';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _stockController,
                                        decoration: InputDecoration(
                                          labelText: 'Stock',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'Enter stock';
                                          final val = int.tryParse(v);
                                          if (val == null || val < 0) return 'Enter valid stock';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<Category>(
                                  value: _selectedCategory,
                                  items: _categories
                                      .map((cat) => DropdownMenuItem(
                                            value: cat,
                                            child: Text(cat.name),
                                          ))
                                      .toList(),
                                  onChanged: (cat) {
                                    setState(() {
                                      _selectedCategory = cat;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    prefixIcon: const Icon(Icons.category_outlined),
                                  ),
                                  validator: (v) => v == null ? 'Select a category' : null,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Product Image",
                                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant,
                                      border: Border.all(
                                        color: _selectedImage == null ? Colors.grey.shade400 : theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _selectedImage == null
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade600),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Tap to select product image',
                                                  style: TextStyle(color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 160,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: _isSubmitting ? null : _submit,
                                    icon: const Icon(Icons.add_circle_outline),
                                    label: _isSubmitting
                                        ? const SizedBox(
                                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Add Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: theme.colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
