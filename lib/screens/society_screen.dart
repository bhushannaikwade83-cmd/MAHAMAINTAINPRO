import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SocietyScreen extends StatelessWidget {
  const SocietyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('🏢 Society Hub'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeatureCard(
            icon: '🚪',
            title: 'Visitor Gate',
            subtitle: 'Manage visitor entries',
            onTap: () => _showModal(context, 'Visitor Gate Management'),
          ),
          _buildFeatureCard(
            icon: '🚗',
            title: 'Parking Management',
            subtitle: 'Request guest parking',
            onTap: () => _showModal(context, 'Parking Management'),
          ),
          _buildFeatureCard(
            icon: '👥',
            title: 'Tenant Management',
            subtitle: 'Register tenants',
            onTap: () => _showModal(context, 'Tenant Management'),
          ),
          _buildFeatureCard(
            icon: '🧾',
            title: 'Bills & Maintenance',
            subtitle: 'View bills and pay online',
            onTap: () => _showModal(context, 'Bills'),
          ),
          _buildFeatureCard(
            icon: '📋',
            title: 'Complaints',
            subtitle: 'Lodge and track complaints',
            onTap: () => _showModal(context, 'Complaints'),
          ),
          _buildFeatureCard(
            icon: '📢',
            title: 'Society Announcements',
            subtitle: 'Latest updates from society',
            onTap: () => _showModal(context, 'Announcements'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }

  void _showModal(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('$title feature details and options'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
