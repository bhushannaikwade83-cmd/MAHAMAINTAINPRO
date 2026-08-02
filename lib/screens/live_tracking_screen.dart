import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Teal Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1B9B8E),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Tracking',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Service Provider Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F5F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1B9B8E), width: 2),
                ),
                child: Column(
                  children: [
                    // Map Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1B9B8E), width: 2),
                      ),
                      child: Text(
                        '🗺️',
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Service Provider Name
                    Text(
                      'Suresh Patil • 1.2 km away',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ETA Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ETA: 11 mins',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B9B8E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Booking Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressItem(
                    number: '1',
                    title: 'Booking Confirmed',
                    subtitle: 'Today • 09:15 AM',
                    isCompleted: true,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressItem(
                    number: '2',
                    title: 'Professional Assigned',
                    subtitle: 'Suresh Patil • 4.9 ⭐',
                    isCompleted: true,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressItem(
                    number: '3',
                    title: 'On the way',
                    subtitle: 'Currently 1.2 km away',
                    isCompleted: false,
                    isInProgress: true,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressItem(
                    number: '4',
                    title: 'Service in Progress',
                    subtitle: 'Waiting for completion',
                    isCompleted: false,
                    isInProgress: false,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildProgressItem({
    required String number,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isInProgress = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF1B9B8E)
                  : (isInProgress ? Colors.grey.shade300 : Colors.grey.shade300),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      number,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
