import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import 'email_settings_screen.dart';
import 'address_settings_screen.dart';
import 'payment_methods_screen.dart';
import 'notifications_settings_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, String>> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('user_email') ?? 'bhushan@example.com',
      'address': prefs.getString('user_address') ?? 'Shri Ramdev Park CHS',
      'city': prefs.getString('user_city') ?? 'Mumbai',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('👤 My Profile'),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _loadProfileData(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final email = data['email'] ?? 'bhushan@example.com';
          final address = data['address'] ?? 'Shri Ramdev Park CHS';
          final city = data['city'] ?? 'Mumbai';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: const Text('👤', style: TextStyle(fontSize: 50)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bhushan Naikwade',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        '+91 9876543210',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: const [
                              Text('28', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Bookings'),
                            ],
                          ),
                          Column(
                            children: const [
                              Text('⭐ 4.8', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Rating'),
                            ],
                          ),
                          Column(
                            children: const [
                              Text('₹12,450', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Spent'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                context,
                '📧 Email',
                email,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmailSettingsScreen()),
                ).then((_) => setState(() {})),
              ),
              _buildSettingsTile(
                context,
                '🏠 Address',
                '$address, $city',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddressSettingsScreen()),
                ).then((_) => setState(() {})),
              ),
              _buildSettingsTile(
                context,
                '💳 Payment Methods',
                'Manage cards & accounts',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
                ),
              ),
              _buildSettingsTile(
                context,
                '🔔 Notifications',
                'Notification settings',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsSettingsScreen()),
                ).then((_) => setState(() {})),
              ),
              _buildSettingsTile(
                context,
                '📱 About',
                'Version 1.0.0',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen(
                                onOtpSent: () {},
                                onOtpPhoneChange: (email) {},
                              )),
                              (route) => false,
                            );
                          },
                          child: const Text('Logout', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
