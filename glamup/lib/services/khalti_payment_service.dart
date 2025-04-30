import 'package:flutter/material.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'api_service.dart';

class KhaltiPaymentService {
  final ApiService apiService;

  KhaltiPaymentService({required this.apiService});

  // Initialize payment configuration
  PaymentConfig getPaymentConfig({
    required double amount, 
    required String productId,
    required String productName,
    String? customerPhone,
  }) {
    // Amount should be in paisa (100 paisa = 1 NPR)
    final amountInPaisa = (amount * 100).toInt();
    
    return PaymentConfig(
      amount: amountInPaisa,
      productIdentity: productId,
      productName: productName,
      productUrl: 'https://glamup.com/products/$productId',
      additionalData: {
        'vendor': 'GlamUp',
        'payment_type': 'order_payment',
      },
      mobile: customerPhone,
      mobileReadOnly: customerPhone != null,
    );
  }

  // Method to initiate payment
  void initiatePayment({
    required BuildContext context,
    required double amount,
    required String productId,
    required String productName,
    String? customerPhone,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onFailure,
  }) {
    final config = getPaymentConfig(
      amount: amount,
      productId: productId,
      productName: productName,
      customerPhone: customerPhone,
    );
    
    KhaltiScope.of(context).pay(
      config: config,
      preferences: [
        PaymentPreference.khalti,
        PaymentPreference.eBanking,
        PaymentPreference.connectIPS,
        PaymentPreference.sct,
      ],
      onSuccess: (successModel) async {
        // Verify the payment with server
        try {
          final verificationResult = await apiService.verifyKhaltiPayment(
            token: successModel.token,
            amount: successModel.amount.toString(),
          );
          onSuccess(verificationResult);
        } catch (e) {
          onFailure('Payment verification failed: ${e.toString()}');
        }
      },
      onFailure: (failureModel) {
        onFailure('Payment failed: ${failureModel.message}');
      },
      onCancel: () {
        onFailure('Payment cancelled by user');
      },
    );
  }
}
