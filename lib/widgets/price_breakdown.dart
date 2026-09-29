import 'package:flutter/material.dart';

class PriceBreakdown extends StatelessWidget {
  final double itemsSubtotal;
  final double addonsTotal;
  final double serviceFee;
  final double travelFee;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final bool expanded;
  final VoidCallback? onExpand;

  const PriceBreakdown({
    Key? key,
    required this.itemsSubtotal,
    required this.addonsTotal,
    required this.serviceFee,
    required this.travelFee,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    this.expanded = false,
    this.onExpand,
  }) : super(key: key);

  String _formatPrice(double price) => '₹${price.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Total
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    _formatPrice(total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Expandable breakdown
            if (expanded) ...[
              _PriceRow('Items Subtotal', itemsSubtotal),
              if (addonsTotal > 0)
                _PriceRow('Add-ons', addonsTotal, color: Colors.orange),
              if (serviceFee > 0)
                _PriceRow('Service Fee', serviceFee, color: Colors.purple),
              if (travelFee > 0)
                _PriceRow('Travel Fee', travelFee, color: Colors.indigo),
              if (taxAmount > 0)
                _PriceRow('Tax (18%)', taxAmount, color: Colors.red.shade600),
              if (discountAmount > 0)
                _PriceRow(
                  'Discount',
                  -discountAmount,
                  color: Colors.green,
                ),
              const Divider(height: 16),
            ] else if (onExpand != null)
              GestureDetector(
                onTap: onExpand,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Price Breakdown',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;

  const _PriceRow(
    this.label,
    this.amount, {
    this.color,
  });

  String _formatPrice(double price) {
    final abs = price.abs();
    final formatted = '₹${abs.toStringAsFixed(0)}';
    return price < 0 ? '-$formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Text(
            _formatPrice(amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
