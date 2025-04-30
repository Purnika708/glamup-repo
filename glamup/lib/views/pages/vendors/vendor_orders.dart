import 'package:flutter/material.dart';
import 'package:glamup/controllers/auth_controller.dart';
import 'package:glamup/controllers/order_controller.dart';
import 'package:glamup/models/order.dart';
import 'package:glamup/models/user.dart';
import 'package:glamup/services/api_service.dart';
import 'package:glamup/views/components/shared_header.dart';
import 'package:intl/intl.dart';

class VendorOrdersPage extends StatefulWidget {
  final Map<String, dynamic>? filterParams;
  
  const VendorOrdersPage({super.key, this.filterParams});

  @override
  _VendorOrdersPageState createState() => _VendorOrdersPageState();
}

class _VendorOrdersPageState extends State<VendorOrdersPage> {
  final OrderController _orderController = OrderController(apiService: ApiService());
  final AuthController _authController = AuthController(apiService: ApiService());
  
  List<Order> orders = [];
  bool isLoading = true;
  String? errorMessage;
  User? currentUser;
  String? selectedStatusFilter;

  final currencyFormat = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    if (widget.filterParams != null && widget.filterParams!.containsKey('filter')) {
      selectedStatusFilter = widget.filterParams!['filter'];
    }
    _loadUserAndOrders();
  }

  Future<void> _loadUserAndOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get the current user
      final user = await _authController.getLoggedInUser();
      if (user == null || user.role.toLowerCase() != 'vendor') {
        setState(() {
          errorMessage = 'Access denied: Only vendors can view this page';
          isLoading = false;
        });
        return;
      }
      
      setState(() {
        currentUser = user;
      });

      // Load all orders - the backend will filter for orders with vendor's products
      final vendorOrders = await _orderController.getOrders();
      
      // Apply filter if selected
      List<Order> filteredOrders = vendorOrders;
      if (selectedStatusFilter != null) {
        filteredOrders = vendorOrders.where(
          (order) => order.status.toLowerCase() == selectedStatusFilter!.toLowerCase()
        ).toList();
      }
      
      setState(() {
        orders = filteredOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _showUpdateStatusDialog(Order order) {
    String newStatus = order.status;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Order Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id}'),
                  const SizedBox(height: 16),
                  const Text('Select new status:'),
                  const SizedBox(height: 8),
                  _buildStatusOptions(newStatus, (value) {
                    setState(() {
                      newStatus = value;
                    });
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateOrderStatus(order.id, newStatus);
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showUpdatePaymentStatusDialog(Order order) {
    String newPaymentStatus = order.paymentStatus;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Payment Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id}'),
                  const SizedBox(height: 16),
                  const Text('Select payment status:'),
                  const SizedBox(height: 8),
                  _buildPaymentStatusOptions(newPaymentStatus, (value) {
                    setState(() {
                      newPaymentStatus = value;
                    });
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _updatePaymentStatus(order.id, newPaymentStatus);
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildStatusOptions(String currentStatus, Function(String) onChanged) {
    return Column(
      children: [
        _buildStatusRadio('pending', 'Pending', currentStatus, onChanged),
        _buildStatusRadio('shipped', 'Shipped', currentStatus, onChanged),
        _buildStatusRadio('delivered', 'Delivered', currentStatus, onChanged),
        _buildStatusRadio('cancelled', 'Cancelled', currentStatus, onChanged),
      ],
    );
  }

  Widget _buildStatusRadio(String value, String label, String groupValue, Function(String) onChanged) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (String? newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  Widget _buildPaymentStatusOptions(String currentStatus, Function(String) onChanged) {
    return Column(
      children: [
        _buildPaymentStatusRadio('pending', 'Pending', currentStatus, onChanged),
        _buildPaymentStatusRadio('completed', 'Completed', currentStatus, onChanged),
        _buildPaymentStatusRadio('failed', 'Failed', currentStatus, onChanged),
      ],
    );
  }

  Widget _buildPaymentStatusRadio(String value, String label, String groupValue, Function(String) onChanged) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (String? newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _orderController.updateOrderStatus(orderId, newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated successfully')),
      );

      _loadUserAndOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status: $e')),
      );
    }
  }

  Future<void> _updatePaymentStatus(int orderId, String newPaymentStatus) async {
    try {
      await _orderController.updatePaymentStatus(orderId, newPaymentStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment status updated successfully')),
      );

      _loadUserAndOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update payment status: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '⏳';
      case 'shipped':
        return '🚚';
      case 'delivered':
        return '✅';
      case 'cancelled':
        return '❌';
      default:
        return '❓';
    }
  }

  IconData _getPaymentIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'cash_on_delivery':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }
  
  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case 'card':
        return 'Card';
      case 'wallet':
        return 'Wallet';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return method;
    }
  }
  @override
  Widget build(BuildContext context) {
    // Check for filter argument from route
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['filter'] != null && args['filter'] is String) {
      if (selectedStatusFilter != args['filter']) {
        selectedStatusFilter = args['filter'];
        // Reload orders with new filter
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadUserAndOrders();
        });
      }
    }
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SharedHeader(
            title: "Orders".toUpperCase(),
            subtitle: "Manage your vendor orders".toUpperCase(),
            expandable: true,
        
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserAndOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      String message = 'No orders found';
      if (selectedStatusFilter != null) {
        message = 'No ${selectedStatusFilter!.toLowerCase()} orders found';
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (selectedStatusFilter != null)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedStatusFilter = null;
                    _loadUserAndOrders();
                  });
                },
                child: const Text('Show All Orders'),
              ),
          ],
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
      child: RefreshIndicator(
        onRefresh: _loadUserAndOrders,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 80), // Added more bottom padding
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/order-details',
                    arguments: order.id,
                  ).then((_) => _loadUserAndOrders());
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Chip(
                            backgroundColor: _getStatusColor(order.status).withOpacity(0.1),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getStatusIcon(order.status),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(order.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.formattedDate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _getPaymentIcon(order.paymentMethod),
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatPaymentMethod(order.paymentMethod),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (order.fullName != null)
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              'Customer: ',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            Expanded(
                              child: Text(
                                order.fullName!,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currencyFormat.format(order.totalAmount),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                    
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showUpdateStatusDialog(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Update Status', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showUpdatePaymentStatusDialog(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Update Payment Status', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
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
    );
  }
}