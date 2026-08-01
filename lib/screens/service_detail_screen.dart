import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceCategory category;

  const ServiceDetailScreen({required this.category, Key? key}) : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Text('←', style: TextStyle(fontSize: 22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image/Header
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _hexToColor(widget.category.bgColor),
                    _hexToColor(widget.category.bgColor).withOpacity(0.5),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  widget.category.icon,
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Title
                  Text(
                    widget.category.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    '⭐ 4.8 (2,340 reviews)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // Available Providers
                  const Text(
                    'Available Service Providers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  // Provider Card 1
                  _buildProviderCard(
                    name: 'Suresh Kumar',
                    rating: 4.9,
                    reviews: 560,
                    price: 499,
                    time: '46 min',
                    badge: '⚡ Insta',
                  ),

                  const SizedBox(height: 12),

                  // Provider Card 2
                  _buildProviderCard(
                    name: 'Rajesh Sharma',
                    rating: 4.7,
                    reviews: 320,
                    price: 599,
                    time: '52 min',
                    badge: null,
                  ),

                  const SizedBox(height: 12),

                  // Provider Card 3
                  _buildProviderCard(
                    name: 'Priya Patel',
                    rating: 4.8,
                    reviews: 450,
                    price: 399,
                    time: '55 min',
                    badge: 'NEW',
                  ),

                  const SizedBox(height: 20),

                  // Service Details
                  const Text(
                    'What\'s Included',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  _buildBulletPoint('Professional & vetted service provider'),
                  _buildBulletPoint('Quality work with 100% satisfaction guarantee'),
                  _buildBulletPoint('Real-time tracking of your service'),
                  _buildBulletPoint('WhatsApp support during service'),

                  const SizedBox(height: 20),

                  // Quantity Selector
                  const Text(
                    'Service Duration / Quantity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Text('−', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          onPressed: quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$quantity hours',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          onPressed: () => setState(() => quantity++),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pricing Summary
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPricingRow('Service Price', '₹${499 * quantity}'),
                        const SizedBox(height: 8),
                        _buildPricingRow('Platform Fee', '₹49'),
                        const Divider(height: 16),
                        _buildPricingRow('Total', '₹${499 * quantity + 49}',
                            isBold: true, isTotal: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Book Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _showBookingConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF25C05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard({
    required String name,
    required double rating,
    required int reviews,
    required int price,
    required String time,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                child: Text('👨', style: TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badge == '⚡ Insta'
                                  ? const Color(0xFFFFF3EC)
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: badge == '⚡ Insta'
                                    ? const Color(0xFFF25C05)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('⭐'),
                        const SizedBox(width: 4),
                        Text(
                          '$rating ($reviews)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$price',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _bookProvider(name, price),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF25C05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Select',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✓', style: TextStyle(color: Color(0xFF16A34A), fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String amount, {bool isBold = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFFF25C05) : Colors.grey,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFFF25C05) : Colors.black,
          ),
        ),
      ],
    );
  }

  void _bookProvider(String providerName, int price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Confirmed! ✓'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider: $providerName'),
            const SizedBox(height: 8),
            Text('Service: ${widget.category.title}'),
            const SizedBox(height: 8),
            Text('Amount: ₹${price * quantity + 49}'),
            const SizedBox(height: 8),
            Text('Duration: $quantity hours'),
            const SizedBox(height: 16),
            const Text('✓ Booking confirmed!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('You will receive a call from the service provider shortly.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Shopping'),
          ),
          ElevatedButton(
            onPressed: () {
              
              
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  void _showBookingConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please select a service provider first!'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (!hex.startsWith('#')) buffer.write('#');
    buffer.write(hex);
    return Color(int.parse(buffer.toString().replaceFirst('#', '0xff')));
  }
}
