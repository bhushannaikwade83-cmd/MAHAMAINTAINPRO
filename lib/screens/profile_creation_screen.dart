import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileCreationScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onProfileCreated;

  const ProfileCreationScreen({
    required this.phoneNumber,
    required this.onProfileCreated,
    super.key,
  });

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  static const String API_BASE_URL = 'https://digitrixmedia.com/mahamaintainpro/api';

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    final fullName = _fullNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (fullName.isEmpty) {
      setState(() => _error = 'Full Name is required');
      return;
    }

    if (email.isEmpty) {
      setState(() => _error = 'Email is required');
      return;
    }

    if (!email.contains('@')) {
      setState(() => _error = 'Enter valid email');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/create-individual.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': widget.phoneNumber,
          'full_name': fullName,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        widget.onProfileCreated();
      } else {
        setState(() => _error = data['message'] ?? 'Failed to create profile');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete Your Profile',
              style: TextStyle(
                fontSize: isSmall ? 24 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2B1B10),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us know you better',
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                color: const Color(0xFF8A7361),
              ),
            ),
            const SizedBox(height: 32),
            // Full Name Field
            Text(
              'Full Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2B1B10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameCtrl,
              enabled: !_loading,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFF0DFD0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF9A4D),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Phone Field (Non-editable)
            Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2B1B10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: widget.phoneNumber),
              enabled: false,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFCF3EA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFF0DFD0),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.lock,
                    color: Color(0xFF8A7361),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Email Field
            Text(
              'Email ID',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2B1B10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'your.email@example.com',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFF0DFD0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF9A4D),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF5350),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _createProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9A4D),
                  disabledBackgroundColor: const Color(0xFFFCDDB4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFFFFF),
                          ),
                        ),
                      )
                    : Text(
                        'Create Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
