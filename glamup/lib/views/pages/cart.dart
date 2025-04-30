import 'package:flutter/material.dart';
import 'package:glamup/controllers/cart_controller.dart';
import 'package:glamup/controllers/address_controller.dart';
import 'package:glamup/controllers/auth_controller.dart';
import 'package:glamup/models/cart.dart';
import 'package:glamup/models/address.dart';
import 'package:glamup/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartController _cartController = CartController(
    apiService: ApiService(),
  );
  final AddressController _addressController = AddressController(
    apiService: ApiService(),
  );
  final AuthController _authController = AuthController(
    apiService: ApiService(),
  );

  List<CartItem> cartItems = [];
  List<Address> addresses = [];
  Address? selectedAddress;
  String selectedPaymentMethod = 'khalti'; // Default payment method
  bool isLoading = true;
  bool isLoadingAddresses = true;
  bool isPlacingOrder = false;
  bool isUserLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Delay the execution to ensure the widget is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    try {
      final user = await _authController.getLoggedInUser();
      if (mounted) {
        setState(() {
          isUserLoggedIn = user != null;
          isLoading = false;
        });

        if (isUserLoggedIn) {
          loadCartItems();
          loadAddresses();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUserLoggedIn = false;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking login status: $e')),
        );
      }
    }
  }

  Future<void> loadCartItems() async {
    if (!isUserLoggedIn) return;

    try {
      setState(() {
        isLoading = true;
      });

      var items = await _cartController.getCartItems();

      if (mounted) {
        setState(() {
          cartItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cart items: $e')),
        );
      }
    }
  }

  Future<void> loadAddresses() async {
    if (!isUserLoggedIn) return;

    try {
      setState(() {
        isLoadingAddresses = true;
      });

      var items = await _addressController.getAddresses();

      if (mounted) {
        setState(() {
          addresses = items;
          if (items.isNotEmpty && selectedAddress == null) {
            selectedAddress = items[0];
          }
          isLoadingAddresses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingAddresses = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load addresses: $e')));
      }
    }
  }

  Future<void> removeItem(int id) async {
    try {
      await _cartController.deleteCartItem(id);
      loadCartItems();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item removed from cart')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove item: $e')));
    }
  }

  Future<void> updateQuantity(int cartId, int productId, int quantity) async {
    if (quantity <= 0) return; // Don't allow zero or negative quantities

    try {
      await _cartController.updateCartItem(cartId, productId, quantity);
      loadCartItems();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update quantity: $e')));
    }
  }

  void _showQuantityDialog(CartItem item) {
    final TextEditingController quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Quantity'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                int? newQuantity = int.tryParse(quantityController.text);
                if (newQuantity != null && newQuantity > 0) {
                  updateQuantity(item.id, item.productId, newQuantity);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddressSelectionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Delivery Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add New'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/address-management',
                      ).then((_) => loadAddresses());
                    },
                  ),
                ],
              ),
              const Divider(),
              isLoadingAddresses
                  ? const Center(child: CircularProgressIndicator())
                  : addresses.isEmpty
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No addresses found. Please add a delivery address.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  : Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        final isSelected = selectedAddress?.id == address.id;

                        return RadioListTile<Address>(
                          value: address,
                          groupValue: selectedAddress,
                          title: Text(
                            address.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${address.addressLine}, ${address.city}, ${address.state} ${address.zipCode}\n${address.phone}',
                          ),
                          onChanged: (Address? value) {
                            setState(() {
                              selectedAddress = value;
                            });
                            Navigator.pop(context);
                          },
                          selected: isSelected,
                          activeColor: Theme.of(context).primaryColor,
                        );
                      },
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  // Method to show payment method dialog with enhanced Khalti UI
  void _showPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),

                    // Khalti option with enhanced styling
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              selectedPaymentMethod == 'khalti'
                                  ? const Color(
                                    0xFF5C2D91,
                                  ) // Khalti brand color
                                  : Colors.grey.shade200,
                          width: selectedPaymentMethod == 'khalti' ? 2 : 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C2D91).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFF5C2D91), // Khalti brand color
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pay with Khalti',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Fast and secure wallet payment',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        value: 'khalti',
                        groupValue: selectedPaymentMethod,
                        onChanged: (String? value) {
                          if (value != null) {
                            setModalState(() {
                              selectedPaymentMethod = value;
                            });
                            setState(() {
                              selectedPaymentMethod = value;
                            });
                          }
                        },
                        activeColor: const Color(
                          0xFF5C2D91,
                        ), // Khalti brand color
                        selected: selectedPaymentMethod == 'khalti',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    // Cash on Delivery option with enhanced styling
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              selectedPaymentMethod == 'cash_on_delivery'
                                  ? Colors.green
                                  : Colors.grey.shade200,
                          width:
                              selectedPaymentMethod == 'cash_on_delivery'
                                  ? 2
                                  : 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.money,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash on Delivery',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Pay when you receive the order',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        value: 'cash_on_delivery',
                        groupValue: selectedPaymentMethod,
                        onChanged: (String? value) {
                          if (value != null) {
                            setModalState(() {
                              selectedPaymentMethod = value;
                            });
                            setState(() {
                              selectedPaymentMethod = value;
                            });
                          }
                        },
                        activeColor: Colors.green,
                        selected: selectedPaymentMethod == 'cash_on_delivery',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor:
                              selectedPaymentMethod == 'khalti'
                                  ? const Color(
                                    0xFF5C2D91,
                                  ) // Khalti brand color
                                  : Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Confirm',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double calculateTotal() {
    // Parse the price as double, multiply by quantity, and accumulate totals
    return cartItems.fold(0.0, (total, item) {
      double price = double.parse(item.productPrice);
      return total + (price * item.quantity);
    });
  }

  Future<void> placeOrder() async {
    if (selectedAddress == null && addresses.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      _showAddressSelectionDialog();
      return;
    } else if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a delivery address')),
      );
      Navigator.pushNamed(context, '/address-management');
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Are you sure you want to place this order?'),
                const SizedBox(height: 16),
                const Text('Order Summary:'),
                Text(
                  '${cartItems.length} items for Rs. ${calculateTotal().toStringAsFixed(2)}',
                ),
                Text(
                  'Payment Method: ${_getPaymentMethodName(selectedPaymentMethod)}',
                ),
                Text('Deliver to: ${selectedAddress?.fullName}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed:
                  isPlacingOrder
                      ? null
                      : () async {
                        Navigator.of(context).pop();
                        await _submitOrder();
                      },
              child:
                  isPlacingOrder
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Place Order'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    if (selectedAddress == null) return;

    // For Khalti payment, we'll redirect to the Khalti payment page
    if (selectedPaymentMethod == 'khalti') {
      final total = calculateTotal();
      initiateKhaltiPayment(context, total);
      return;
    }

    setState(() {
      isPlacingOrder = true;
    });

    try {
      Map<String, dynamic> orderData = {
        'address_id': selectedAddress!.id,
        'payment_method': selectedPaymentMethod,
      };

      // Send order data to backend
      await _cartController.placeOrder(orderData);

      // Clear cart after successful order
      setState(() {
        cartItems = [];
        isPlacingOrder = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        isPlacingOrder = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'Digital Wallet';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'khalti':
        return 'Khalti';
      default:
        return method;
    }
  }

  void initiateKhaltiPayment(BuildContext context, double totalAmount) {
    // Navigate to Khalti payment page
    Navigator.pushNamed(
      context,
      '/khalti-payment',
      arguments: {
        'amount': totalAmount.toInt(), // Khalti expects integer amount
        'productId': 'CART-PAYMENT', // You can generate a unique ID
        'productName': 'Glam-Up Cart Payment',
      },
    ).then((result) {
      // Handle the result when user returns from payment page
      if (result != null &&
          result is Map<String, dynamic> &&
          result['success'] == true) {
        // Payment successful, place the order with Khalti payment info
        _placeOrderAfterKhaltiPayment(result['data']);
      } else {
        // Payment failed or was cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was not completed. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _placeOrderAfterKhaltiPayment(
    Map<String, dynamic> paymentData,
  ) async {
    if (selectedAddress == null) return;

    setState(() {
      isPlacingOrder = true;
    });

    try {
      // Create order data with payment information
      Map<String, dynamic> orderData = {
        'address_id': selectedAddress!.id,
        'payment_method': 'khalti',
        'payment_amount': paymentData['amount'],
        'payment_mobile': paymentData['mobile'],
      };

      // Send order data to backend
      await _cartController.placeOrder(orderData);

      // Clear cart after successful order
      setState(() {
        cartItems = [];
        isPlacingOrder = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully with Khalti payment!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        isPlacingOrder = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "My Cart",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isUserLoggedIn)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh cart',
              onPressed: loadCartItems,
            ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        flexibleSpace: Container(
          padding: EdgeInsets.only(bottom: 100),
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
              : !isUserLoggedIn
              ? _buildLoginRequired(context)
              : cartItems.isEmpty
              ? _buildEmptyCart(context)
              : _buildCartContent(context),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            "Login Required",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              "Please login to view your cart and make purchases",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text("Login"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/products');
            },
            child: const Text(
              "Continue Shopping",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Add items to your cart to make a purchase",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_bag),
            label: const Text("Continue Shopping"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/products');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context) {
    final total = calculateTotal();

    // Calculate subtotal for each item
    final subtotals =
        cartItems.map((item) {
          double price = double.parse(item.productPrice);
          return price * item.quantity;
        }).toList();

    return Column(
      children: [
        // Address selection
        GestureDetector(
          onTap: _showAddressSelectionDialog,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Delivery Address",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                isLoadingAddresses
                    ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : selectedAddress == null
                    ? Text(
                      "No address selected. Tap to select.",
                      style: TextStyle(color: Colors.grey[700]),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedAddress!.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedAddress!.addressLine}, ${selectedAddress!.city}, ${selectedAddress!.state} ${selectedAddress!.zipCode}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),

        // Payment method selection
        GestureDetector(
          onTap: _showPaymentMethodDialog,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Payment Method",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      selectedPaymentMethod == 'card'
                          ? Icons.credit_card
                          : selectedPaymentMethod == 'wallet'
                          ? Icons.account_balance_wallet
                          : selectedPaymentMethod == 'bank_transfer'
                          ? Icons.account_balance
                          : selectedPaymentMethod == 'khalti'
                          ? Icons.account_balance_wallet
                          : Icons.money,
                      size: 20,
                      color:
                          selectedPaymentMethod == 'khalti'
                              ? Colors.purple
                              : Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getPaymentMethodName(selectedPaymentMethod),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color:
                            selectedPaymentMethod == 'khalti'
                                ? Colors.purple
                                : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Cart items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              var item = cartItems[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
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
                        child: CachedNetworkImage(
                          imageUrl:
                              item.productImage.startsWith('http')
                                  ? item.productImage
                                  : 'http://localhost/Glamup${item.productImage}',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, error, stackTrace) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
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
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rs. ${item.productPrice} each",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  "Subtotal: ",
                                  style: TextStyle(fontSize: 14),
                                ),
                                Flexible(
                                  child: Text(
                                    "Rs. ${subtotals[index].toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Quantity Controls
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showQuantityDialog(item),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (item.quantity > 1) {
                                        updateQuantity(
                                          item.id,
                                          item.productId,
                                          item.quantity - 1,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.remove,
                                        size: 18,
                                        color:
                                            item.quantity > 1
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showQuantityDialog(item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        "${item.quantity}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      updateQuantity(
                                        item.id,
                                        item.productId,
                                        item.quantity + 1,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.add,
                                        size: 18,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => removeItem(item.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Cart Summary and Checkout - Fixed to bottom
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total (${cartItems.length} ${cartItems.length == 1 ? 'item' : 'items'})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Rs. ${total.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // For very narrow screens, stack buttons vertically
                    if (constraints.maxWidth < 320) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isPlacingOrder ? null : placeOrder,
                            child:
                                isPlacingOrder
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text("Place Order"),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/products',
                              );
                            },
                            child: const Text("Continue Shop"),
                          ),
                        ],
                      );
                    }

                    // For normal-sized screens, use horizontal layout
                    return Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/products',
                              );
                            },
                            child: const Text("Continue Shop"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isPlacingOrder ? null : placeOrder,
                            child:
                                isPlacingOrder
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text("Place Order"),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
