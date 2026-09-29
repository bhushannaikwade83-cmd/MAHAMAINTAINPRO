import 'package:flutter/material.dart';

class CartItemCard extends StatelessWidget {
  final String serviceName;
  final String? packageName;
  final int quantity;
  final double unitPrice;
  final double itemSubtotal;
  final List<String>? addons;
  final VoidCallback? onRemove;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const CartItemCard({
    Key? key,
    required this.serviceName,
    this.packageName,
    required this.quantity,
    required this.unitPrice,
    required this.itemSubtotal,
    this.addons,
    this.onRemove,
    this.onIncrement,
    this.onDecrement,
  }) : super(key: key);

  String _formatPrice(double price) => '₹${price.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service name and remove button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (packageName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            packageName!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.grey.shade600,
                    onPressed: onRemove,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Add-ons
            if (addons != null && addons!.isNotEmpty) ...[
              Text(
                'Add-ons:',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: addons!
                    .map(
                      (addon) => Chip(
                        label: Text(
                          addon,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.orange.shade100,
                        labelStyle: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 11,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Quantity and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity selector
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Material(
                          child: InkWell(
                            onTap: onDecrement,
                            child: const Icon(
                              Icons.remove,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 28,
                        alignment: Alignment.center,
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Material(
                          child: InkWell(
                            onTap: onIncrement,
                            child: const Icon(
                              Icons.add,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(itemSubtotal),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                    ),
                    Text(
                      '${_formatPrice(unitPrice)} per item',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
