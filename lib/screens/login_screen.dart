import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';
import '../main.dart' show authRepositoryProvider;
import 'otp_verification_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onOtpSent;
  final Function(String) onOtpPhoneChange;
  final VoidCallback? onBackPress;

  const LoginScreen({
    required this.onOtpSent,
    required this.onOtpPhoneChange,
    this.onBackPress = null,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _phoneFocused = false;
  final FocusNode _phoneFocus = FocusNode();
  String? _userRole;
  DateTime? _logoTapDownTime;

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
    _phoneFocus.addListener(() {
      setState(() => _phoneFocused = _phoneFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final phoneNumber = _phoneController.text.trim();

      // Validate phone
      if (!_isValidPhone(phoneNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 10-digit phone number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Send OTP via API
      final response = await _sendOtpApi(phoneNumber);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to OTP verification
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              phoneNumber: phoneNumber,
              onBackPress: () => Navigator.pop(context),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send OTP'),
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

  Future<Map<String, dynamic>> _sendOtpApi(String phoneNumber) async {
    try {
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/send-otp.php');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  bool _isValidPhone(String phone) {
    return phone.length == 10 && phone.contains(RegExp(r'^[0-9]{10}$'));
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
                  // Premium Gradient background
                  Container(
                    width: double.infinity,
                    height: screenHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.saffron,
                          AppTheme.saffron.withOpacity(0.85),
                          const Color(0xFFF25C05),
                        ],
                      ),
                    ),
                  ),

                  // Modern decorative blobs
                  Positioned(
                    top: -80,
                    right: -60,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    left: -80,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.saffron.withOpacity(0.15),
                      ),
                    ),
                  ),

                  // Main content
                  Column(
                    children: [
                      // Premium Header with logo
                      Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + (isSmall ? 16 : 24),
                          bottom: isSmall ? 20 : 32,
                          left: isSmall ? 12 : 16,
                          right: isSmall ? 12 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: 1,
                              duration: const Duration(milliseconds: 600),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 32,
                                      offset: const Offset(0, 12),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, -6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(36),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: isSmall ? 110 : 140,
                                    height: isSmall ? 110 : 140,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmall ? 18 : 24),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'MahaMaintain\n',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmall ? 26 : 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                      height: 1.1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Pro',
                                    style: TextStyle(
                                      color: const Color(0xFFFFD700),
                                      fontSize: isSmall ? 26 : 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmall ? 10 : 14),
                            Text(
                              'महाराष्ट्राचा विश्वास • Premium Services',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isSmall ? 12 : 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Form Card - Premium Glassmorphic
                      Container(
                        margin: EdgeInsets.fromLTRB(
                          isSmall ? 12 : 16,
                          isSmall ? 20 : 28,
                          isSmall ? 12 : 16,
                          isSmall ? 16 : 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.98),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: AppTheme.saffron.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 18 : 24,
                          vertical: isSmall ? 20 : 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back Button
                            if (widget.onBackPress != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: isSmall ? 12 : 16),
                                child: GestureDetector(
                                  onTap: widget.onBackPress,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.saffron.withOpacity(0.15),
                                          AppTheme.saffron.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.saffron.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: AppTheme.saffron,
                                      size: isSmall ? 20 : 22,
                                    ),
                                  ),
                                ),
                              ),
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: isSmall ? 20 : 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.saffron,
                                letterSpacing: -0.6,
                              ),
                            ),
                            SizedBox(height: isSmall ? 8 : 10),
                            Text(
                              'Sign in to access your premium services',
                              style: TextStyle(
                                fontSize: isSmall ? 12 : 13,
                                color: Colors.grey.shade600,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isSmall ? 16 : 20),

                            // Email Input Field - Simple & Clean
                            TextField(
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: 'Enter 10-digit mobile number',
                                hintStyle: TextStyle(
                                  fontSize: isSmall ? 12 : 13,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w400,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: isSmall ? 12 : 14,
                                  horizontal: 16,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 12, right: 8),
                                  child: Icon(
                                    Icons.email_outlined,
                                    color: Colors.grey.shade600,
                                    size: isSmall ? 18 : 20,
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(),
                              ),
                              style: TextStyle(
                                fontSize: isSmall ? 14 : 15,
                                fontWeight: FontWeight.w500,
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                            SizedBox(height: isSmall ? 14 : 16),
                            Text(
                              'By continuing, you agree to our Terms & Privacy Policy',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmall ? 10 : 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: isSmall ? 14 : 16),
                            AnimatedScale(
                              scale: _isValidPhone(_phoneController.text) ? 1.02 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: SizedBox(
                                width: double.infinity,
                                height: isSmall ? 50 : 56,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap:
                                        _isValidPhone(_phoneController.text) && !_isLoading
                                            ? _sendOtp
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
                                          BoxShadow(
                                            color: AppTheme.saffron.withOpacity(0.15),
                                            blurRadius: 30,
                                            offset: const Offset(0, 12),
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
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Send OTP',
                                                    style: TextStyle(
                                                      fontSize: isSmall ? 15 : 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    Icons.arrow_forward,
                                                    color: Colors.white,
                                                    size: isSmall ? 18 : 20,
                                                  ),
                                                ],
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
