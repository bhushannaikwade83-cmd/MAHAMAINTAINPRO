import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SocietyRegistrationScreen extends StatefulWidget {
  final VoidCallback? onRegistrationComplete;

  const SocietyRegistrationScreen({
    this.onRegistrationComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<SocietyRegistrationScreen> createState() =>
      _SocietyRegistrationScreenState();
}

class _SocietyRegistrationScreenState extends State<SocietyRegistrationScreen> {
  final _secretaryNameController = TextEditingController();
  final _secretaryPhoneController = TextEditingController();
  final _societyNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _secretaryNameController.dispose();
    _secretaryPhoneController.dispose();
    _societyNameController.dispose();
    super.dispose();
  }

  void _registerSociety() {
    if (_secretaryNameController.text.isEmpty ||
        _secretaryPhoneController.text.isEmpty ||
        _societyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_secretaryPhoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Society registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onRegistrationComplete?.call();
      Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.saffron, AppTheme.saffronDark],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Register Your Society 🏢',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock all society features',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Registration Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Society Name Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Society Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _societyNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your society name',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.apartment, color: AppTheme.saffron),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.saffron, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Secretary Name Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secretary\'s Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _secretaryNameController,
                        decoration: InputDecoration(
                          hintText: 'Full name of society secretary',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.person, color: AppTheme.saffron),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.saffron, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Secretary Phone Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secretary\'s Phone Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _secretaryPhoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: InputDecoration(
                          hintText: 'Enter 10-digit phone number',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.phone, color: AppTheme.saffron),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.saffron, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          counterText: '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerSociety,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.saffron,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Register Society',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.saffron.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.saffron.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ℹ️',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Society registration helps unlock all community features. We\'ll verify this information with your secretary.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
