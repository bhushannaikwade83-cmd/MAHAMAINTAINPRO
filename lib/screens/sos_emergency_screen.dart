import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';
import '../services/firebase_service.dart';
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
  bool _alertActuallyDelivered = false;
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

  /// Real GPS fix for the alert - previously this always sent the literal
  /// string 'Unknown location' because nothing anywhere in the app ever
  /// wrote to the 'user_location' SharedPreferences key it used to read.
  Future<Position?> _getCurrentPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _triggerAlert() async {
    setState(() => _sending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'User';

      final position = await _getCurrentPosition();
      final userLocation = position != null
          ? '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'
          : 'Location unavailable';

      // Get user's FCM token
      final firebaseService = FirebaseService();
      final userFcmToken = await firebaseService.getToken();

      // Get emergency contacts' FCM tokens from saved contacts
      List<String> emergencyFcmTokens = [];
      for (var contact in _contacts) {
        final fcmToken = contact['fcm_token'];
        if (fcmToken != null && fcmToken.isNotEmpty) {
          emergencyFcmTokens.add(fcmToken);
        }
      }

      // Call API to send SOS alert - identity comes from the JWT server-side,
      // not a client-supplied phone number.
      final response = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/send-sos-fcm.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'user_name': userName,
          'location': userLocation,
          if (position != null) 'latitude': position.latitude,
          if (position != null) 'longitude': position.longitude,
          'contacts': _contacts,
          'fcm_tokens': emergencyFcmTokens, // Emergency contacts' tokens
          'user_fcm_token': userFcmToken // Sender's token for admin
        }),
      );

      final data = response.statusCode == 200 ? jsonDecode(response.body) : null;
      final contactsNotified = data != null && data['success'] == true ? (data['contacts_notified'] as int? ?? 0) : 0;
      final delivered = response.statusCode == 200 && data?['success'] == true;

      // Also log locally
      final log = prefs.getStringList('sos_alert_log') ?? [];
      log.add(jsonEncode({
        'contacts': _contacts,
        'timestamp': DateTime.now().toString(),
        'location': userLocation,
        'api_response': delivered ? 'sent' : 'failed',
        'contacts_notified': contactsNotified,
      }));
      await prefs.setStringList('sos_alert_log', log);

      // Brief pause so the "sending" state is felt
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      setState(() {
        _sending = false;
        _alertSent = true;
        _alertActuallyDelivered = delivered && contactsNotified > 0;
      });

      // Only claim contacts were notified if the backend actually confirmed
      // it - previously this showed "Help is on the way" and green
      // checkmarks against every contact even when the request had failed
      // or no contact had a registered FCM token to push to.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_alertActuallyDelivered
              ? 'SOS sent - $contactsNotified contact${contactsNotified == 1 ? '' : 's'} notified.'
              : 'Alert saved, but we could not confirm any contact was notified. Please also call them directly.'),
          backgroundColor: _alertActuallyDelivered ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending SOS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      backgroundColor: _alertSent
          ? (_alertActuallyDelivered ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1))
          : const Color(0xFFFFF3F3),
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
                Text(_alertActuallyDelivered ? '🚨' : '⚠️', style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 24),
                Text(
                  _alertActuallyDelivered
                      ? 'Help is on the way.\nPlease wait...'
                      : 'Alert saved, but delivery\ncould not be confirmed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _alertActuallyDelivered ? const Color(0xFF1B5E20) : const Color(0xFF8A6D00),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _alertActuallyDelivered
                      ? 'Your emergency contacts have been notified.'
                      : 'We could not confirm any contact received a push notification - please also call them directly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 32),
                if (_alertActuallyDelivered)
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
