import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('📱 About'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with app info
            Container(
              color: AppTheme.saffron.withOpacity(0.1),
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.saffron,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'MMP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MahaMaintain Pro',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'About MahaMaintain Pro',
                    content:
                        'MahaMaintain Pro is your complete solution for home services and society management. We connect you with trusted service providers and help manage your residential society operations seamlessly.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Key Features',
                    items: [
                      '🏠 Home Services Booking',
                      '🏢 Society Management',
                      '💳 Secure Payments',
                      '📍 Live Tracking',
                      '⭐ Verified Service Providers',
                      '🔔 Real-time Notifications',
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Contact Us',
                    items: [
                      'Email: support@mahamaintain.com',
                      'Phone: +91 98765 43210',
                      'Website: www.mahamaintain.com',
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Legal',
                    items: [
                      'Terms of Service',
                      'Privacy Policy',
                      'Cancellation Policy',
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: const [
                        Text(
                          '© 2024 MahaMaintain Pro',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'All rights reserved',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
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

  Widget _buildSection({required String title, String? content, List<String>? items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (content != null)
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.6,
            ),
          ),
        if (items != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
