import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:glamup/models/user.dart';
import 'package:glamup/views/pages/address_management.dart';
import 'package:glamup/views/components/shared_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('glamupAuthBox');
    var userJson = box.get('user');
    User? user = userJson != null ? User.fromJson(Map<String, dynamic>.from(userJson)) : null;

    return Scaffold(
      body: user == null 
        ? _buildLoggedOutView(context)
        : _buildLoggedInView(context, user),
    );
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_circle_outlined,
                  size: 80,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Welcome to GlamUp",
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Sign in to access your personalized shopping experience and manage your orders",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Sign In",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Register Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register-select');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              _buildFeatureCard(
                icon: Icons.shopping_basket_rounded,
                title: 'Browse as Guest', 
                description: 'Continue shopping without signing in',
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/');
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, User user) {
    final bool isAdmin = user.role.toLowerCase() == 'admin';
    final bool isVendor = user.role.toLowerCase() == 'vendor';
    
    return CustomScrollView(
      slivers: [
        SharedHeader(
          title: 'Profile',
          expandable: true,
          subtitle: user.email,
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor,
                    Colors.pink.shade300,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
            
              ],
            ),
          ),
        ),
        
        // User Info
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.grey.shade600
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getRoleTitle(user.role),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Role-specific Management Button
        if (isAdmin || isVendor)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context, 
                    isAdmin ? '/admin-dashboard' : '/vendor-dashboard'
                  );
                },
                icon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.store),
                label: Text(
                  isAdmin ? 'Admin Dashboard' : 'Vendor Dashboard',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAdmin ? Colors.blue.shade700 : Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        
        // Section Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              "Your Account",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ),
        
        // Account Options
        SliverList(
          delegate: SliverChildListDelegate([
            _buildProfileOption(
              context,
              icon: Icons.shopping_bag_outlined,
              title: "My Orders",
              subtitle: "View and track your orders",
              onTap: () {
                Navigator.pushNamed(context, '/my-orders');
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.location_on_outlined,
              title: "My Addresses",
              subtitle: "Manage shipping addresses",
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const AddressManagementPage())
                );
              },
            ),
            // Additional options for different roles
            if (isVendor)
              _buildProfileOption(
                context,
                icon: Icons.inventory_2_outlined,
                title: "My Products",
                subtitle: "Manage your product listings",
                onTap: () {
                  Navigator.pushNamed(context, '/vendor-products');
                },
              ),
              
            if (isAdmin)
              _buildProfileOption(
                context,
                icon: Icons.people_outlined,
                title: "Manage Users",
                subtitle: "View and manage user accounts",
                onTap: () {
                  Navigator.pushNamed(context, '/admin-users');
                },
              ),
            
            const Divider(height: 32, thickness: 1),
            
            _buildProfileOption(
              context,
              icon: Icons.help_outline,
              title: "Help & Support",
              subtitle: "Get assistance with your account",
              onTap: () {
                Navigator.pushNamed(context, '/support');
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.policy_outlined,
              title: "Privacy Policy",
              subtitle: "Read our privacy policy",
              onTap: () {
                Navigator.pushNamed(context, '/privacy');
              },
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.pushNamed(context, '/profile-edit');
                        if (updated == true) {
                          // Optionally, you can refresh the page or show a message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text(
                        "Update Profile",
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Show confirmation dialog
                        bool confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('LOG OUT'),
                              ),
                            ],
                          ),
                        ) ?? false;
                        
                        if (confirm) {
                          var glamupAuthBox = Hive.box('glamupAuthBox');
                          await glamupAuthBox.clear();
                          Navigator.pushReplacementNamed(context, '/');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        "Log Out",
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ],
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Function onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
          onTap: () => onTap(),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Function onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.pink,
                  size: 24,
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
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.blue.shade700;
      case 'vendor':
        return Colors.teal;
      default:
        return Colors.pink;
    }
  }
  
  String _getRoleTitle(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'ADMINISTRATOR';
      case 'vendor':
        return 'VENDOR';
      default:
        return 'CUSTOMER';
    }
  }
}