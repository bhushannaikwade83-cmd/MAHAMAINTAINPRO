import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('📋 My Bookings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Bookings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBookingCard(
                    service: 'Bathroom Deep Clean',
                    serviceProvider: 'Suresh',
                    date: 'Today at 2:30 PM',
                    status: 'In Progress',
                    statusColor: Colors.green,
                    emoji: '🧹',
                  ),
                  const SizedBox(height: 12),
                  _buildBookingCard(
                    service: 'Electrical Repair',
                    serviceProvider: 'Raj Kumar',
                    date: 'Tomorrow at 10:00 AM',
                    status: 'Confirmed',
                    statusColor: Colors.blue,
                    emoji: '🔧',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Past Bookings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBookingCard(
                    service: 'Plumbing Service',
                    serviceProvider: 'Anil Singh',
                    date: 'Jul 25, 2024',
                    status: 'Completed',
                    statusColor: Colors.grey,
                    emoji: '🔨',
                  ),
                  const SizedBox(height: 12),
                  _buildBookingCard(
                    service: 'Salon Service',
                    serviceProvider: 'Priya',
                    date: 'Jul 18, 2024',
                    status: 'Completed',
                    statusColor: Colors.grey,
                    emoji: '💆',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBookingCard({
    required String service,
    required String serviceProvider,
    required String date,
    required String status,
    required Color statusColor,
    required String emoji,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$serviceProvider • $date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
