import 'package:flutter/material.dart';
import 'package:glamup/controllers/auth_controller.dart';
import 'package:glamup/models/user.dart';
import 'package:glamup/services/api_service.dart';

class VendorDashboardPage extends StatefulWidget {
  const VendorDashboardPage({super.key});

  @override
  _VendorDashboardPageState createState() => _VendorDashboardPageState();
}

class _VendorDashboardPageState extends State<VendorDashboardPage> {
  final AuthController _authController = AuthController(apiService: ApiService());
  bool isLoading = true;
  User? currentUser;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = await _authController.getLoggedInUser();
      if (user == null || user.role.toLowerCase() != 'vendor') {
        setState(() {
          errorMessage = 'Access denied: Only vendors can access this dashboard';
          isLoading = false;
        });
        return;
      }

      setState(() {
        currentUser = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorView()
              : _buildDashboardContent(),
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
              errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadVendorData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor welcome card
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
                    Text(
                      'Welcome, ${currentUser?.name}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your products and orders from your vendor dashboard.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dashboard stats cards
            Row(
              children: [
                _buildStatCard(
                  context,
                  'Products',
                  Icons.inventory,
                  Colors.blue,
                  () {
                    Navigator.pushNamed(context, '/vendor-products');
                  },
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  'Orders',
                  Icons.shopping_bag,
                  Colors.green,
                  () {
                    Navigator.pushNamed(context, '/vendor-orders');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick access section
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickAccessItem(
              context,
              'Manage Products',
              'Add, edit, and remove your products',
              Icons.inventory_2,
              Colors.deepPurple,
              () {
                Navigator.pushNamed(context, '/vendor-products');
              },
            ),
            const SizedBox(height: 12),
            _buildQuickAccessItem(
              context,
              'Add New Product',
              'Create a new product listing',
              Icons.add_circle,
              Colors.pink,
              () {
                Navigator.pushNamed(context, '/vendor-add-product');
              },
            ),
            const SizedBox(height: 12),
            _buildQuickAccessItem(
              context,
              'View All Orders',
              'Check and manage customer orders',
              Icons.shopping_cart,
              Colors.amber,
              () {
                Navigator.pushNamed(context, '/vendor-orders');
              },
            ),
            const SizedBox(height: 12),
            _buildQuickAccessItem(
              context,
              'Pending Orders',
              'View orders awaiting processing',
              Icons.pending_actions,
              Colors.orange,
              () {
                Navigator.pushNamed(
                  context,
                  '/vendor-orders',
                  arguments: {'filter': 'pending'},
                );
              },
            ),
            const SizedBox(height: 12),
    
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}