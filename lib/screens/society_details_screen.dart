import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';

class SocietyDetailsScreen extends StatefulWidget {
  final String individualName;
  final String individualPhone;
  final String individualEmail;
  final String individualAddress;

  const SocietyDetailsScreen({
    required this.individualName,
    required this.individualPhone,
    required this.individualEmail,
    required this.individualAddress,
    Key? key,
  }) : super(key: key);

  @override
  State<SocietyDetailsScreen> createState() => _SocietyDetailsScreenState();
}

class _SocietyDetailsScreenState extends State<SocietyDetailsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _societyNameController = TextEditingController();
  final TextEditingController _societyAddressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _flatNumberController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _societyNameController.dispose();
    _societyAddressController.dispose();
    _pincodeController.dispose();
    _flatNumberController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isValidForm() {
    return _societyNameController.text.trim().isNotEmpty &&
        _societyAddressController.text.trim().isNotEmpty &&
        _pincodeController.text.trim().length == 6 &&
        _flatNumberController.text.trim().isNotEmpty;
  }

  void _submitRegistration() async {
    if (!_isValidForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://digitrixmedia.com/api/signup.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'individual_name': widget.individualName,
          'individual_phone': widget.individualPhone,
          'individual_email': widget.individualEmail,
          'individual_address': widget.individualAddress,
          'society_name': _societyNameController.text.trim(),
          'society_address': _societyAddressController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'flat_number': _flatNumberController.text.trim(),
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Registration submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: screenHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.saffron.withOpacity(0.95),
                          AppTheme.saffronDark,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 16 : 20,
                      vertical: MediaQuery.of(context).padding.top + (isSmall ? 10 : 20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            Text(
                              'Society Details',
                              style: TextStyle(
                                fontSize: isSmall ? 20 : 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                        SizedBox(height: isSmall ? 24 : 32),
                        Container(
                          margin: EdgeInsets.only(bottom: isSmall ? 16 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.98),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 18 : 24,
                            vertical: isSmall ? 20 : 28,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Society Information',
                                style: TextStyle(
                                  fontSize: isSmall ? 16 : 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.saffron,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: isSmall ? 14 : 16),
                              _buildTextField(
                                controller: _societyNameController,
                                label: 'Society Name',
                                hint: 'e.g., Shri Ramdev Park CHS',
                                icon: Icons.apartment_outlined,
                                isSmall: isSmall,
                              ),
                              SizedBox(height: isSmall ? 12 : 14),
                              _buildTextField(
                                controller: _societyAddressController,
                                label: 'Society Address',
                                hint: 'Enter complete society address',
                                icon: Icons.location_on_outlined,
                                isSmall: isSmall,
                                maxLines: 3,
                              ),
                              SizedBox(height: isSmall ? 12 : 14),
                              _buildTextField(
                                controller: _pincodeController,
                                label: 'Pincode',
                                hint: '6 digit pincode',
                                icon: Icons.pin_outlined,
                                isSmall: isSmall,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                              ),
                              SizedBox(height: isSmall ? 12 : 14),
                              _buildTextField(
                                controller: _flatNumberController,
                                label: 'Flat/Unit Number',
                                hint: 'e.g., A-101',
                                icon: Icons.door_front_door_outlined,
                                isSmall: isSmall,
                              ),
                              SizedBox(height: isSmall ? 18 : 24),
                              Container(
                                padding: EdgeInsets.all(isSmall ? 12 : 14),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'ℹ️ Your society details will be verified by our admin. You will receive email confirmation once approved.',
                                  style: TextStyle(
                                    fontSize: isSmall ? 11 : 12,
                                    color: Colors.blue.shade700,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmall ? 16 : 20),
                              SizedBox(
                                width: double.infinity,
                                height: isSmall ? 50 : 56,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isValidForm() && !_isLoading
                                        ? _submitRegistration
                                        : null,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppTheme.saffron,
                                            AppTheme.saffron.withOpacity(0.85),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.saffron.withOpacity(0.35),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isLoading
                                            ? SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation(
                                                    Colors.white,
                                                  ),
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Text(
                                                'Submit Registration',
                                                style: TextStyle(
                                                  fontSize: isSmall ? 14 : 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                      ),
                                    ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isSmall,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isSmall ? 6 : 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: isSmall ? 12 : 13,
              color: Colors.grey.shade500,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.saffron,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: isSmall ? 12 : 14,
              horizontal: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                icon,
                color: Colors.grey.shade600,
                size: isSmall ? 18 : 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            counterText: '',
          ),
          style: TextStyle(
            fontSize: isSmall ? 14 : 15,
            color: Colors.black87,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
