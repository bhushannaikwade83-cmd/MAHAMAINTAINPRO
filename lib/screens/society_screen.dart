import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SocietyScreen extends StatelessWidget {
  const SocietyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('🏢 Society'),
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
                    'Shri Ramdev Park CHS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Mira Road, Mumbai',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Links',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickLink('📄 View Bill', Colors.orange),
                  const SizedBox(height: 10),
                  _buildQuickLink('✏️ File Complaint', Colors.red),
                  const SizedBox(height: 10),
                  _buildQuickLink('🛵 Visitor Gate', Colors.blue),
                  const SizedBox(height: 10),
                  _buildQuickLink('🔑 Tenant Info', Colors.green),
                  const SizedBox(height: 10),
                  _buildQuickLink('🚗 Parking Status', Colors.purple),
                  const SizedBox(height: 24),
                  Text(
                    'Announcements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnnouncement(
                    'Maintenance Due',
                    'July maintenance charges are due by 25th July',
                    '3 days ago',
                  ),
                  const SizedBox(height: 10),
                  _buildAnnouncement(
                    'Society Meeting',
                    'Annual society meeting scheduled for 30th July at 6 PM',
                    '1 week ago',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildQuickLink(String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Icon(Icons.arrow_forward, color: color, size: 20),
        ],
      ),
    );
  }

  static Widget _buildAnnouncement(
    String title,
    String description,
    String timeAgo,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
