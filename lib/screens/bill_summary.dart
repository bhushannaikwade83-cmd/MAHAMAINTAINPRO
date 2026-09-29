import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class BillSummary extends StatelessWidget {
  final double subtotal;
  final double travelFee;
  final double serviceFee;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final String? couponCode;
  final VoidCallback? onEditCoupon;

  const BillSummary({
    required this.subtotal,
    this.travelFee = 0,
    this.serviceFee = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.total,
    this.couponCode,
    this.onEditCoupon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Bill Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Subtotal
          _buildRow(
            'Subtotal',
            '₹${subtotal.toStringAsFixed(2)}',
            textColor: Colors.black87,
          ),

          // Travel Fee
          if (travelFee > 0) ...[
            const SizedBox(height: 8),
            _buildRow(
              'Travel Fee',
              '₹${travelFee.toStringAsFixed(2)}',
              textColor: Colors.grey.shade700,
            ),
          ],

          // Service Fee
          if (serviceFee > 0) ...[
            const SizedBox(height: 8),
            _buildRow(
              'Service Charges',
              '₹${serviceFee.toStringAsFixed(2)}',
              textColor: Colors.grey.shade700,
            ),
          ],

          // Tax
          if (taxAmount > 0) ...[
            const SizedBox(height: 8),
            _buildRow(
              'GST (18%)',
              '₹${taxAmount.toStringAsFixed(2)}',
              textColor: Colors.grey.shade700,
            ),
          ],

          // Discount
          if (discountAmount > 0) ...[
            const Divider(height: 16),
            _buildRow(
              couponCode != null ? 'Discount ($couponCode)' : 'Discount',
              '-₹${discountAmount.toStringAsFixed(2)}',
              textColor: Colors.green.shade700,
              isDiscount: true,
            ),
          ],

          // Total (Sticky)
          const Divider(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.saffron.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.saffron,
                  ),
                ),
              ],
            ),
          ),

          // Coupon Edit (if applied)
          if (couponCode != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onEditCoupon,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Change Coupon',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Savings info
          if (discountAmount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'You saved ₹${discountAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color? textColor,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textColor ?? Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: textColor ?? Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
