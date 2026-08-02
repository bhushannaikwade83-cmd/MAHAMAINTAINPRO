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
  final List<Map<String, dynamic>> services = [
    {
      'name': 'Hair Cut & Styling (Women)',
      'emoji': '✂️',
      'duration': '45-60 min',
      'rating': 4.9,
      'price': 399,
      'quantity': 0,
    },
    {
      'name': 'Facial (Basic / D-Tan)',
      'emoji': '🧴',
      'duration': '60 min',
      'rating': 4.8,
      'price': 499,
      'quantity': 0,
    },
    {
      'name': 'Full Body Waxing',
      'emoji': '✨',
      'duration': '90 min',
      'rating': 4.7,
      'price': 799,
      'quantity': 0,
    },
    {
      'name': 'Head Massage',
      'emoji': '💆‍♀️',
      'duration': '30 min',
      'rating': 4.9,
      'price': 299,
      'quantity': 0,
    },
    {
      'name': 'Manicure & Pedicure',
      'emoji': '💅',
      'duration': '60 min',
      'rating': 4.8,
      'price': 599,
      'quantity': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  RichText(
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
                          style: const TextStyle(
                            fontSize: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Services List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(
                  services.length,
                  (index) => _buildServiceCard(index),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Book Now Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Service booked! Redirecting to checkout...'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(int index) {
    final service = services[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            service['emoji'],
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '⏱️ ${service['duration']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '⭐ ${service['rating']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${service['price']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.saffron,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (services[index]['quantity'] > 0) {
                        services[index]['quantity']--;
                      }
                    });
                  },
                  child: const Text(
                    '−',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.saffron,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${services[index]['quantity']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      services[index]['quantity']++;
                    });
                  },
                  child: const Text(
                    '+',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.saffron,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
