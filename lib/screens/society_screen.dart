import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'approval_pending_screen.dart';

/// Shown on the Individual account's Society tab until they've registered
/// their society secretary's details. Submitting doesn't unlock the
/// dashboard immediately - it puts the request in a "pending admin
/// approval" state, matching how a real society would onboard a member
/// (the Committee account reviews and issues a Society Member Account ID).
class SocietyScreen extends StatefulWidget {
  final VoidCallback? onRegistrationSuccess;

  const SocietyScreen({
    this.onRegistrationSuccess,
    Key? key,
  }) : super(key: key);

  @override
  State<SocietyScreen> createState() => _SocietyScreenState();
}

class _SocietyScreenState extends State<SocietyScreen> {
  final _secretaryNameController = TextEditingController();
  final _secretaryPhoneController = TextEditingController();
  bool _loaded = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _submit() async {
    final name = _secretaryNameController.text.trim();
    final phone = _secretaryPhoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // Get user_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('userPhone') ?? '';

      // Query database to get user_id from phone
      final userResponse = await http.get(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/get-user-id.php?phone=$userPhone'),
      ).timeout(const Duration(seconds: 10));

      if (userResponse.statusCode != 200) {
        throw Exception('Could not find your account. Please try again.');
      }

      final userData = jsonDecode(userResponse.body);
      final userId = userData['user_id'];

      // Save userId to SharedPreferences for future status checks
      await prefs.setInt('userId', userId);

      final response = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/register-secretary.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Secretary registration successful, now adding to society_customers_individual...');

          // Add user to society_customers_individual with pending access
          try {
            final memberResponse = await http.post(
              Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/add-society-member.php'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'user_id': userId,
                'is_committee': 0,
                'is_enabled': 0,
              }),
            ).timeout(const Duration(seconds: 10));

            print('📊 Member add response: statusCode=${memberResponse.statusCode}, body=${memberResponse.body}');

            if (memberResponse.statusCode == 409) {
              // Duplicate registration
              print('⚠️ User already registered (duplicate attempt)');
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Text('⚠️', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 8),
                      Expanded(child: Text('Already Registered')),
                    ],
                  ),
                  content: const Text(
                    'You have already submitted a registration for this society. '
                    'Please wait for admin approval.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onRegistrationSuccess != null) {
                          widget.onRegistrationSuccess!();
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('OK', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              return;
            } else if (memberResponse.statusCode == 201 || memberResponse.statusCode == 200) {
              final memberData = jsonDecode(memberResponse.body);
              if (memberData['success'] == true) {
                print('🎉 User added to society_customers_individual with pending access');
              }
            }
          } catch (e) {
            print('⚠️ Warning: Could not add to society_customers_individual: $e');
            // Don't fail registration if member table add fails
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('secretary_name', name);
          await prefs.setString('secretary_phone', phone);
          await prefs.setString('society_registration_status', 'pending');

          if (!mounted) return;
          // Show success and wait for auto-refresh
          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Text('✅', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Expanded(child: Text('Registration Submitted')),
                ],
              ),
              content: const Text(
                'Your details have been saved. '
                'The approval pending screen will appear shortly.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Trigger parent refresh to show pending screen
                    if (widget.onRegistrationSuccess != null) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        widget.onRegistrationSuccess!();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          return;
        }
      }

      final errorData = jsonDecode(response.body);
      final errorMsg = errorData['message'] ?? 'Failed to submit registration';

      // Check for duplicate registration
      if (errorMsg.contains('Duplicate') || errorMsg.contains('already') || errorMsg.contains('exists')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already registered! Please refresh to see your status.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _checkStatusAgain() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('secretary_phone');

    if (phone == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/check-secretary-status.php?phone=$phone'),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['exists'] == true) {
          if (data['status'] == 'active') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Approval granted! Refreshing...'),
                backgroundColor: Colors.green,
              ),
            );
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) setState(() {});
            });
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still pending. Check back later!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _secretaryNameController.dispose();
    _secretaryPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: false,
        title: const Text('Add Secretary Info'),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.saffron.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.person_add_alt_1, size: 48, color: AppTheme.saffron),
          ),
          const SizedBox(height: 20),
          const Text(
            'Society Secretary Info',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Add your society secretary\'s details to access the dashboard',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Secretary Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _secretaryNameController,
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: 'e.g., Rajesh Kumar',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.saffron),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppTheme.saffron, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Phone Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _secretaryPhoneController,
            enabled: !_submitting,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+91 98765 43210',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.saffron),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppTheme.saffron, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffron,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 3,
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Access Society Dashboard',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.saffron.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.saffron.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ℹ️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This information is used to access your society\'s features and notifications.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
