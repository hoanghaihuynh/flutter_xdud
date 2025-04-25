import 'package:flutter/material.dart';
import '../utils/formatCurrency.dart';

class PaymentMethodModal extends StatelessWidget {
  final Function(String) onPaymentMethodSelected;
  final double totalAmount;
  final bool isLoading; // Thêm trạng thái loading

  const PaymentMethodModal({
    Key? key,
    required this.onPaymentMethodSelected,
    required this.totalAmount,
    this.isLoading = false, // Mặc định là false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose your payment method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPaymentOption(
                  context,
                  icon: Icons.payment,
                  title: 'Pay with VNPAY',
                  subtitle: 'Secure online payment',
                  onTap: isLoading ? null : () => onPaymentMethodSelected('VNPAY'),
                  isDisabled: isLoading,
                ),
                const SizedBox(height: 16),
                _buildPaymentOption(
                  context,
                  icon: Icons.money,
                  title: 'Pay with CASH',
                  subtitle: 'Pay on delivery',
                  onTap: isLoading ? null : () => onPaymentMethodSelected('CASH'),
                  isDisabled: isLoading,
                ),
                const SizedBox(height: 20),
                Text(
                  'Total: ${formatCurrency(totalAmount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, 
                size: 32, 
                color: isDisabled 
                  ? Colors.grey 
                  : Theme.of(context).primaryColor
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDisabled ? Colors.grey : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDisabled 
                          ? Colors.grey.shade400 
                          : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}