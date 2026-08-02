import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceName;
  final String serviceEmoji;
  final String description;

  const ServiceDetailScreen({
    required this.serviceName,
    required this.serviceEmoji,
    required this.description,
    Key? key,
  }) : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  late List<Map<String, dynamic>> services;

  @override
  void initState() {
    super.initState();
    services = [
      {'name': 'Hair Cut & Styling (Women)', 'emoji': '✂️', 'duration': '45-60 min', 'rating': 4.9, 'price': 399, 'quantity': 0},
      {'name': 'Facial (Basic / D-Tan)', 'emoji': '🧴', 'duration': '60 min', 'rating': 4.8, 'price': 499, 'quantity': 0},
      {'name': 'Full Body Waxing', 'emoji': '✨', 'duration': '90 min', 'rating': 4.7, 'price': 799, 'quantity': 0},
      {'name': 'Head Massage', 'emoji': '💆‍♀️', 'duration': '30 min', 'rating': 4.9, 'price': 299, 'quantity': 0},
      {'name': 'Manicure & Pedicure', 'emoji': '💅', 'duration': '60 min', 'rating': 4.8, 'price': 599, 'quantity': 0},
    ];
  }

  int get totalPrice => services.fold(0, (sum, item) => sum + ((item['price'] as int) * (item['quantity'] as int)));
  int get totalServices => services.fold(0, (sum, item) => sum + (item['quantity'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 8,
              right: 16,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(left: -8),
                    child: const Icon(Icons.arrow_back, size: 24, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 16),
                // Title with emoji
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.serviceName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: ' ${widget.serviceEmoji}',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    widget.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(services.length, (index) => _buildServiceCard(index)),
              ),
            ),
          ),

          // Bottom Action Bar
          if (totalServices > 0)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 16,
              ),
              child: Column(
                children: [
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalServices ${totalServices == 1 ? 'Service' : 'Services'} Selected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹$totalPrice',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Book Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Booking $totalServices service(s) for ₹$totalPrice'),
                            backgroundColor: AppTheme.saffron,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.saffron,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(int index) {
    final service = services[index];
    final isSelected = service['quantity'] > 0;

    return GestureDetector(
      onTap: () => setState(() => service['quantity']++),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.saffron.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.saffron : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(service['emoji'], style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name'],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '⏱️ ${service['duration']}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '⭐ ${service['rating']}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${service['price']}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.saffron),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Quantity Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (service['quantity'] > 0) service['quantity']--;
                      });
                    },
                    child: Text('−', style: TextStyle(fontSize: 16, color: AppTheme.saffron, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text('${service['quantity']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => service['quantity']++),
                    child: Text('+', style: TextStyle(fontSize: 16, color: AppTheme.saffron, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
