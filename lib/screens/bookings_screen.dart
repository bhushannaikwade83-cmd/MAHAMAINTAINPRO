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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBookingCard(
            status: 'Active',
            service: 'Bathroom Deep Clean',
            provider: 'Suresh Kumar',
            time: 'Today • 2:30 PM - 4:30 PM',
            amount: '₹548',
            icon: '✅',
          ),
          _buildBookingCard(
            status: 'Completed',
            service: 'AC Maintenance',
            provider: 'Rajesh Sharma',
            time: 'Yesterday • 10:00 AM',
            amount: '₹799',
            icon: '✓',
          ),
          _buildBookingCard(
            status: 'Scheduled',
            service: 'Plumbing Repair',
            provider: 'Priya Patel',
            time: 'Tomorrow • 11:00 AM',
            amount: '₹399',
            icon: '📅',
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({
    required String status,
    required String service,
    required String provider,
    required String time,
    required String amount,
    required String icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  service,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'Active' ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: status == 'Active' ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Provider: $provider', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('$icon $time', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.saffron,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                  ),
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
