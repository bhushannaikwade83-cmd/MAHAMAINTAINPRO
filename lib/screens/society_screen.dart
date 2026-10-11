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
  int? _societyId;

  @override
  void initState() {
    super.initState();
    _initializeSociety();
  }

  Future<void> _initializeSociety() async {
    final prefs = await SharedPreferences.getInstance();
    // Get default society or the one user belongs to
    // For now, using society_id 1 as default, admin can configure this
    _societyId = prefs.getInt('societyId') ?? 1;
  }

  Future<void> _submit() async {
    final name = _secretaryNameController.text.trim();
    final phone = _secretaryPhoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final response = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/register-secretary.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'society_id': _societyId ?? 1,
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registration submitted! Awaiting admin approval.'),
              backgroundColor: Colors.green,
            ),
          );
          if (widget.onRegistrationSuccess != null) {
            widget.onRegistrationSuccess!();
          }
          return;
        }
      }

      final errorData = jsonDecode(response.body);
      final errorMsg = errorData['message'] ?? 'Failed to submit registration';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
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
