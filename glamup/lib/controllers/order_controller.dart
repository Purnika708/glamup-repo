import 'dart:convert';
import 'package:glamup/models/order-detail.dart';
import 'package:glamup/models/order.dart';
import 'package:glamup/services/api_service.dart';

class OrderController {
  final ApiService apiService;

  OrderController({required this.apiService});

  Future<List<Order>> getOrders() async {
    try {
      final response = await apiService.get('/order.php');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch orders');
      }

      final jsonData = jsonDecode(response.body);
      final List<dynamic> ordersList = jsonData['data'];

      return ordersList.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<OrderDetail> getOrderDetail(int orderId) async {
    try {
      final response = await apiService.get('/order.php?id=$orderId');
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch order details');
      }

      final jsonData = jsonDecode(response.body);
      final orderData = jsonData['data'];

      return OrderDetail.fromJson(orderData);
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }

  Future<void> cancelOrder(int orderId) async {
    try {
      final response = await apiService.delete('/order.php', {
        'order_id': orderId,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel order');
      }
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await apiService.put('/order.php', {
        'order_id': orderId,
        'status': status,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> updatePaymentStatus(int orderId, String paymentStatus) async {
    try {
      final response = await apiService.patch('/order.php', {
        'action': 'update_payment',
        'order_id': orderId,
        'payment_status': paymentStatus,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to update payment status');
      }
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }
}
