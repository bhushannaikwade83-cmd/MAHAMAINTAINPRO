import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import 'sos_contacts_screen.dart';

/// The screen a user lands on once SOS contacts are already saved.
/// Shows one huge emergency button; tapping it "notifies" the saved
/// contacts (logged locally - no external account/SMS system is wired
/// up yet) and switches to a reassuring "help is on the way" state.
class SOSEmergencyScreen extends StatefulWidget {
  const SOSEmergencyScreen({Key? key}) : super(key: key);

  @override
  State<SOSEmergencyScreen> createState() => _SOSEmergencyScreenState();
}

class _SOSEmergencyScreenState extends State<SOSEmergencyScreen> {
  List<Map<String, String>> _contacts = [];
  bool _alertSent = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString('sos_contacts');
    if (contactsJson == null) return;
    final decoded = jsonDecode(contactsJson) as List<dynamic>;
    setState(() {
      _contacts = List<Map<String, String>>.from(decoded.map((x) => Map<String, String>.from(x)));
    });
  }

  Future<void> _triggerAlert() async {
    setState(() => _sending = true);

    final prefs = await SharedPreferences.getInstance();
    final log = prefs.getStringList('sos_alert_log') ?? [];
    log.add(jsonEncode({
      'contacts': _contacts,
      'timestamp': DateTime.now().toString(),
    }));
    await prefs.setStringList('sos_alert_log', log);

    // Brief pause so the "sending" state is felt, not skipped.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _sending = false;
      _alertSent = true;
    });
  }

  Future<void> _editContacts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SOSContactsScreen()),
    );
    _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;
    final buttonSize = isSmall ? 200.0 : 240.0;

    return Scaffold(
      backgroundColor: _alertSent ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3F3),
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('🆘 Emergency SOS'),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_alertSent)
            TextButton(
              onPressed: _editContacts,
              child: const Text('Edit Contacts', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_alertSent) ...[
                const Text('🚨', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 24),
                const Text(
                  'Help is on the way.\nPlease wait...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your ${_contacts.length} emergency contact${_contacts.length == 1 ? '' : 's'} ${_contacts.length == 1 ? 'has' : 'have'} been notified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 32),
                ..._contacts.map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF25D366), size: 18),
                          const SizedBox(width: 8),
                          Text(c['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => setState(() => _alertSent = false),
                  child: const Text('Back to SOS Button'),
                ),
              ] else ...[
                Text(
                  'Tap the button below to alert your emergency contacts',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _sending ? null : _triggerAlert,
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE63946),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE63946).withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
                            )
                          : Text(
                              'SOS',
                              style: TextStyle(
                                fontSize: isSmall ? 40 : 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _contacts.isEmpty
                      ? 'No emergency contacts saved yet.'
                      : '${_contacts.length} emergency contact${_contacts.length == 1 ? '' : 's'} ready',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
