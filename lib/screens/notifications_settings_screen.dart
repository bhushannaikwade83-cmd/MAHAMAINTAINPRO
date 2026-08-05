import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool orderUpdates = true;
  bool promotionalOffers = false;
  bool reminderNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('🔔 Notification Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Your Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNotificationTile(
                      title: 'Push Notifications',
                      subtitle: 'Get notifications on your device',
                      value: pushNotifications,
                      onChanged: (value) {
                        setState(() => pushNotifications = value);
                      },
                    ),
                    const Divider(),
                    _buildNotificationTile(
                      title: 'Email Notifications',
                      subtitle: 'Receive emails for important updates',
                      value: emailNotifications,
                      onChanged: (value) {
                        setState(() => emailNotifications = value);
                      },
                    ),
                    const Divider(),
                    _buildNotificationTile(
                      title: 'Order Updates',
                      subtitle: 'Get updates about your orders',
                      value: orderUpdates,
                      onChanged: (value) {
                        setState(() => orderUpdates = value);
                      },
                    ),
                    const Divider(),
                    _buildNotificationTile(
                      title: 'Promotional Offers',
                      subtitle: 'Receive special offers and deals',
                      value: promotionalOffers,
                      onChanged: (value) {
                        setState(() => promotionalOffers = value);
                      },
                    ),
                    const Divider(),
                    _buildNotificationTile(
                      title: 'Reminders',
                      subtitle: 'Get reminder notifications',
                      value: reminderNotifications,
                      onChanged: (value) {
                        setState(() => reminderNotifications = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification settings saved!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffron,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.saffron,
          ),
        ],
      ),
    );
  }
}
