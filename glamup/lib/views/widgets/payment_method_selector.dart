import 'package:flutter/material.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selectedPaymentMethod;
  final VoidCallback onTap;

  const PaymentMethodSelector({
    Key? key,
    required this.selectedPaymentMethod,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getPaymentMethodColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPaymentMethodIcon(),
                color: _getPaymentMethodColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPaymentMethodName(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodName() {
    switch (selectedPaymentMethod) {
      case 'khalti':
        return 'Khalti Digital Wallet';
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'Digital Wallet';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return 'Select Payment Method';
    }
  }

  IconData _getPaymentMethodIcon() {
    switch (selectedPaymentMethod) {
      case 'khalti':
        return Icons.account_balance_wallet;
      case 'cash_on_delivery':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'bank_transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor() {
    switch (selectedPaymentMethod) {
      case 'khalti':
        return const Color(0xFF5C2D91); // Khalti purple color
      case 'cash_on_delivery':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'wallet':
        return Colors.orange;
      case 'bank_transfer':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}