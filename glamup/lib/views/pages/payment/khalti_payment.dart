import 'package:flutter/material.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

class KhaltiPaymentPage extends StatefulWidget {
  final int amount;
  final String productId;
  final String productName;

  const KhaltiPaymentPage({
    Key? key,
    required this.amount,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<KhaltiPaymentPage> createState() => _KhaltiPaymentPageState();
}

class _KhaltiPaymentPageState extends State<KhaltiPaymentPage> {
  @override
  Widget build(BuildContext context) {
    // Convert amount to paisa (required by Khalti)
    final amountInPaisa = widget.amount * 100;
    
    // Configure payment
    final config = PaymentConfig(
      amount: amountInPaisa,
      productIdentity: widget.productId,
      productName: widget.productName,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section with Order Details
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Product:'),
                        Flexible(
                          child: Text(
                            widget.productName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'NPR ${(widget.amount).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Single Payment Option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Complete Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Khalti Payment Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      KhaltiScope.of(context).pay(
                        config: config,
                        preferences: [PaymentPreference.khalti],
                        onSuccess: onSuccess,
                        onFailure: onFailure,
                        onCancel: onCancel,
                      
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/khaltilogo.png',
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Khalti Digital Wallet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Fast and secure payment method',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.pink,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Payment Progress Indicator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.pink.shade300),
                    const SizedBox(width: 8),
                    Text(
                      'Cart',
                      style: TextStyle(color: Colors.pink.shade300, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 15,
                      height: 2,
                      color: Colors.pink.shade300,
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.circle, color: Colors.pink.shade300),
                    const SizedBox(width: 8),
                    Text(
                      'Payment',
                      style: TextStyle(color: Colors.pink.shade300, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 15,
                      height: 2,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.circle_outlined, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'Complete',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
              
              // Secure Payment Note
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.pink.shade300),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your payment information is securely processed by Khalti.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onSuccess(PaymentSuccessModel success) {
    // Handle successful payment
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Payment Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text('Transaction ID: ${success.idx}'),
              Text('Amount: Rs. ${success.amount / 100}'),
              Text('Mobile: ${success.mobile}'),
              Text('Product ID: ${success.productIdentity}'),
              Text('Product Name: ${success.productName}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close dialog and navigate back
                Navigator.pop(context);
                Navigator.pop(context, {
                  'success': true,
                  'data': {
                    'idx': success.idx,
                    'amount': success.amount,
                    'mobile': success.mobile,
                    'productIdentity': success.productIdentity,
                    'productName': success.productName,
                  },
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void onFailure(PaymentFailureModel failure) {
    // Handle payment failure
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Payment Failed'),
          content: Text(failure.message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void onCancel() {
    // Handle payment cancellation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment was cancelled'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
