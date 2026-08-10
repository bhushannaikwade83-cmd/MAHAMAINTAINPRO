import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import 'dart:convert';
import 'sos_emergency_screen.dart';

/// First-run (and edit) form for the 5 SOS emergency contacts.
/// On save, moves straight to [SOSEmergencyScreen] - contacts are never
/// shown back as a standalone managed list.
class SOSContactsScreen extends StatefulWidget {
  const SOSContactsScreen({Key? key}) : super(key: key);

  @override
  State<SOSContactsScreen> createState() => _SOSContactsScreenState();
}

class _SOSContactsScreenState extends State<SOSContactsScreen> {
  late List<TextEditingController> nameControllers;
  late List<TextEditingController> phoneControllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    nameControllers = List.generate(5, (_) => TextEditingController());
    phoneControllers = List.generate(5, (_) => TextEditingController());
    _prefillExistingContacts();
  }

  Future<void> _prefillExistingContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString('sos_contacts');
    if (contactsJson == null) return;
    final decoded = jsonDecode(contactsJson) as List<dynamic>;
    final contacts = List<Map<String, String>>.from(decoded.map((x) => Map<String, String>.from(x)));
    for (var i = 0; i < contacts.length && i < 5; i++) {
      nameControllers[i].text = contacts[i]['name'] ?? '';
      phoneControllers[i].text = contacts[i]['phone'] ?? '';
    }
  }

  Future<void> _saveContacts() async {
    List<Map<String, String>> contacts = [];

    for (int i = 0; i < 5; i++) {
      if (nameControllers[i].text.isNotEmpty && phoneControllers[i].text.isNotEmpty) {
        contacts.add({
          'name': nameControllers[i].text,
          'phone': phoneControllers[i].text,
        });
      }
    }

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one contact'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_contacts', jsonEncode(contacts));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SOSEmergencyScreen()),
    );
  }

  @override
  void dispose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    for (var controller in phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3ED),
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('🆘 SOS Emergency Contacts'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFFECEC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Emergency Contact Setup',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '📱 Add up to 5 trusted contacts.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🚨 When you press the SOS button, these contacts will be alerted.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.5,
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
                  Text(
                    'Add Emergency Contacts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: nameControllers[index],
                                enabled: !_saving,
                                decoration: InputDecoration(
                                  hintText: 'Contact Name (e.g., Mom, Dad, Sister)',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: phoneControllers[index],
                                enabled: !_saving,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Phone Number (e.g., +91 98765 43210)',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveContacts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.saffron,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '💾 Save Contacts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
