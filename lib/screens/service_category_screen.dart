import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ServiceCategoryScreen extends StatefulWidget {
  final String categoryName;
  final String categoryEmoji;
  final String description;
  final List<Map<String, dynamic>> services;

  const ServiceCategoryScreen({
    required this.categoryName,
    required this.categoryEmoji,
    required this.description,
    required this.services,
    Key? key,
  }) : super(key: key);

  @override
  State<ServiceCategoryScreen> createState() => _ServiceCategoryScreenState();
}

class _ServiceCategoryScreenState extends State<ServiceCategoryScreen> {
  late List<Map<String, dynamic>> _services;

  @override
  void initState() {
    super.initState();
    _services = widget.services.map((s) => <String, dynamic>{...s, 'quantity': 0}).toList();
  }

  int get totalPrice => _services.fold(0, (sum, item) => sum + ((item['price'] as int) * (item['quantity'] as int)));
  int get totalServices => _services.fold(0, (sum, item) => sum + (item['quantity'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.saffron, AppTheme.saffronDark],
              ),
            ),
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
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.arrow_back, size: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                // Title with emoji and badge if new
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: widget.categoryName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: ' ${widget.categoryEmoji}',
                        style: const TextStyle(fontSize: 28),
                      ),
                      if (widget.categoryName.contains('New') || widget.description.contains('New'))
                        TextSpan(
                          text: '\n◆ New',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  _services.length,
                  (index) => _buildServiceCard(index),
                ),
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
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
    final service = _services[index];
    final isSelected = service['quantity'] > 0;

    return GestureDetector(
      onTap: () => setState(() => service['quantity']++),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.saffron.withOpacity(0.05) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.saffron : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(service['emoji'] ?? '🔧', style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name'] ?? 'Service',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (service['duration'] != null)
                        Text(
                          '⏱️ ${service['duration']}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      if (service['rating'] != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '⭐ ${service['rating']}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${service['price'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.saffron,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
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
                    child: Text(
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
                    '${service['quantity']}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => service['quantity']++),
                    child: Text(
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
      ),
    );
  }
}
