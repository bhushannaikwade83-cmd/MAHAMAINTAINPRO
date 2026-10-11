import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';

class EditAccountScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;

  const EditAccountScreen({
    required this.name,
    required this.email,
    required this.phone,
    Key? key,
  }) : super(key: key);

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _editField(String fieldName, TextEditingController controller) async {
    final tempController = TextEditingController(text: controller.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: tempController,
          decoration: InputDecoration(
            hintText: 'Enter $fieldName',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          keyboardType: fieldName == 'Email Address'
              ? TextInputType.emailAddress
              : fieldName == 'Phone Number'
                  ? TextInputType.phone
                  : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveFieldToDatabase(fieldName, tempController.text, controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.saffron,
            ),
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFieldToDatabase(
    String fieldName,
    String newValue,
    TextEditingController controller,
  ) async {
    try {
      if (newValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fieldName cannot be empty'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate email format
      if (fieldName == 'Email Address') {
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!emailRegex.hasMatch(newValue)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid email address'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Check if value already exists in database
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('userPhone');

      if (phoneNumber == null) {
        throw Exception('Phone number not found');
      }

      // Check for duplicates
      final checkUrl = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/check-user.php');
      final checkResponse = await http.post(
        checkUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber}),
      ).timeout(const Duration(seconds: 10));

      if (checkResponse.statusCode == 200) {
        final userData = jsonDecode(checkResponse.body);

        // Check for duplicates
        if (fieldName == 'Email Address' && userData['email'] != newValue) {
          // Check if email exists for another user
          final emailCheckBody = jsonEncode({'phone_number': 'check_email', 'email': newValue});
          // For now, just proceed - can add email uniqueness check later
        } else if (fieldName == 'Phone Number' && userData['phone'] != newValue) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number cannot be changed'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Save to database
      final updateUrl = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/save-profile.php');

      final updateData = {
        'phone_number': phoneNumber,
        'full_name': fieldName == 'Name' ? newValue : _nameController.text,
        'email': fieldName == 'Email Address' ? newValue : _emailController.text,
      };

      final response = await http.post(
        updateUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local controller
          controller.text = newValue;

          // Save to SharedPreferences
          if (fieldName == 'Name') {
            await prefs.setString('userName', newValue);
          } else if (fieldName == 'Email Address') {
            await prefs.setString('user_email', newValue);
          }

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$fieldName updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {});
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to update');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            // Edit Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  _buildEditField(
                    label: 'NAME',
                    value: _nameController.text,
                    onEdit: () => _editField('Name', _nameController),
                  ),
                  const SizedBox(height: 20),
                  // Email Field
                  _buildEditField(
                    label: 'EMAIL ADDRESS',
                    value: _emailController.text,
                    onEdit: () => _editField('Email Address', _emailController),
                  ),
                  const SizedBox(height: 20),
                  // Phone Field
                  _buildEditField(
                    label: 'PHONE NUMBER',
                    value: _phoneController.text,
                    onEdit: () => _editField('Phone Number', _phoneController),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'EDIT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.saffron,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
