import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  late bool pushNotifications;
  late bool emailNotifications;
  late bool orderUpdates;
  late bool promotionalOffers;
  late bool reminderNotifications;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pushNotifications = prefs.getBool('notif_push') ?? true;
      emailNotifications = prefs.getBool('notif_email') ?? true;
      orderUpdates = prefs.getBool('notif_orders') ?? true;
      promotionalOffers = prefs.getBool('notif_promo') ?? false;
      reminderNotifications = prefs.getBool('notif_reminder') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_push', pushNotifications);
      await prefs.setBool('notif_email', emailNotifications);
      await prefs.setBool('notif_orders', orderUpdates);
      await prefs.setBool('notif_promo', promotionalOffers);
      await prefs.setBool('notif_reminder', reminderNotifications);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.saffron,
          title: const Text('🔔 Notification Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              onPressed: _saveSettings,
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
