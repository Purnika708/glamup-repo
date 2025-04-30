import 'package:flutter/material.dart';
import 'package:glamup/models/user.dart';
import 'package:glamup/models/wishlist.dart';
import 'package:glamup/views/pages/address_management.dart';
import 'package:glamup/views/pages/auth/change-password.dart';
import 'package:glamup/views/pages/auth/check-otp.dart';
import 'package:glamup/views/pages/auth/forgot-password.dart';
import 'package:glamup/views/pages/auth/login.dart';
import 'package:glamup/views/pages/auth/register.dart';
import 'package:glamup/views/pages/auth/register_select.dart';
import 'package:glamup/views/pages/auth/register_vendor.dart';
import 'package:glamup/views/pages/cart.dart';
import 'package:glamup/views/pages/home.dart';
import 'package:glamup/views/pages/order-detail.dart';
import 'package:glamup/views/pages/orders.dart';
import 'package:glamup/views/pages/privacy.dart';
import 'package:glamup/views/pages/product-detail.dart';
import 'package:glamup/views/pages/products.dart';
import 'package:glamup/views/pages/profile.dart';
import 'package:glamup/views/pages/profile-edit.dart';
import 'package:glamup/views/pages/support.dart';
import 'package:glamup/views/pages/wishlist.dart';
import 'package:glamup/views/pages/vendors/vendor_details.dart';
import 'package:glamup/views/pages/vendors/vendor_list.dart';
import 'package:glamup/views/pages/vendors/vendor_products.dart';
import 'package:glamup/views/pages/vendors/vendor_dashboard.dart';
import 'package:glamup/views/pages/vendors/vendor_orders.dart';
import 'package:glamup/views/pages/vendors/vendor_add_product.dart';
import 'package:glamup/views/pages/vendors/vendor_edit_product.dart';
import 'package:glamup/views/pages/payment/khalti_payment.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

const String testPublicKey = 'test_public_key_d5d9f63743584dc38753056b0cc737d5';

void main() async {
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(WishlistItemAdapter());

  // Open Hive boxes
  await Hive.openBox('glamupAuthBox');
  await Hive.openBox<WishlistItem>('wishlistBox');

  var glamupAuthBox = Hive.box('glamupAuthBox');
  bool isLoggedIn = glamupAuthBox.containsKey('user');

  runApp(GlamUpApp(isLoggedIn: isLoggedIn));
}

class GlamUpApp extends StatelessWidget {
  final bool isLoggedIn;
  const GlamUpApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return KhaltiScope(
      publicKey: testPublicKey,
      enabledDebugging: true,
      builder: (context, navKey) {
        return MaterialApp(
          localizationsDelegates: const [KhaltiLocalizations.delegate],
          debugShowCheckedModeBanner: false,
          title: 'Glam-Up',
          navigatorKey: navKey,
          theme: ThemeData(primarySwatch: Colors.pink),
          home: const MainLayout(),
          routes: {
            '/home': (context) => const MainLayout(),
            '/support': (context) => const SupportPage(),
            '/privacy': (context) => const PrivacyPolicyPage(),
            '/products': (context) => const ProductsPage(),
            '/cart': (context) => const CartPage(),
            '/wishlist': (context) => const WishlistPage(),
            '/profile': (context) => const ProfilePage(),
            '/profile-edit': (context) => const ProfileEditPage(),
            '/login': (context) => const LoginPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/check-otp': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              return CheckOtpPage(email: args['email']);
            },
            '/change-password': (context) {
              // we need args email and otp to change password
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              return ChangePasswordPage(email: args['email'], otp: args['otp']);
            },
            '/register': (context) => const RegisterCustomerPage(),
            '/register-select': (context) => const RegisterSelectionPage(),
            '/register-vendor': (context) => const RegisterVendorPage(),
            '/address-management': (context) => const AddressManagementPage(),
            '/product-details': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as int;
              return ProductDetailsPage(productId: args);
            },
            '/my-orders': (context) => const OrderListPage(),
            '/order-details': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;
              if (args is int) {
                return OrderDetailPage(orderId: args);
              }
              return const Scaffold(
                body: Center(child: Text('Invalid order ID')),
              );
            },
            // Vendor routes
            '/vendors': (context) => const VendorListPage(),
            '/vendor-details': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as int;
              return VendorDetailsPage(vendorId: args);
            },
            '/vendor-products': (context) => const VendorProductsPage(),
            '/vendor-dashboard': (context) => const VendorDashboardPage(),
            '/vendor-orders': (context) => const VendorOrdersPage(),
            '/vendor-add-product': (context) => const VendorAddProductPage(),
            '/vendor-edit-product': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as int;
              return VendorEditProductPage(productId: args);
            },
            // Payment route
            '/khalti-payment': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>;
              return KhaltiPaymentPage(
                amount: args['amount'],
                productId: args['productId'],
                productName: args['productName'],
              );
            },
          },
        );
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  bool get isVendor =>
      Hive.box('glamupAuthBox').get('user')?['role'] == 'vendor';

  List<Widget> get _pages {
    if (isVendor) {
      return [
        const MainScreen(),
        const ProductsPage(),
        const VendorDashboardPage(),
        const ProfilePage(),
      ];
    } else {
      return [
        const MainScreen(),
        const ProductsPage(),
        const WishlistPage(),
        const CartPage(),
        const ProfilePage(),
      ];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    if (isVendor) {
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: "Home",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: "Shop",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: "Dashboard",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: "Profile",
        ),
      ];
    } else {
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: "Home",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: "Shop",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite),
          label: "Wishlist",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: "Cart",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: "Profile",
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }
}
