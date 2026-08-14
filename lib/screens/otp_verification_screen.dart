import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';
import 'profile_setup_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final VoidCallback? onBackPress;

  const OtpVerificationScreen({
    required this.phoneNumber,
    this.onBackPress,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 6;

  void _handleOtpInput(String value, int index) {
    if (value.length > 1) {
      _otpControllers[index].text = value[value.length - 1];
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    setState(() {});
  }

  void _verifyOtp() async {
    if (!_isOtpComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otp = _otpCode;

      // Verify OTP via API
      final response = await _verifyOtpApi(widget.phoneNumber, otp);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to profile setup
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupScreen(
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'OTP verification failed'),
            backgroundColor: Colors.red,
          ),
        );
        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
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

  Future<Map<String, dynamic>> _verifyOtpApi(String phoneNumber, String otp) async {
    try {
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/verify-otp.php');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phoneNumber,
          'otp': otp,
        }),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.saffron,
                        AppTheme.saffron.withOpacity(0.85),
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
                      if (widget.onBackPress != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: widget.onBackPress,
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
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: isSmall ? 20 : 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.saffron,
                                letterSpacing: -0.6,
                              ),
                            ),
                            SizedBox(height: isSmall ? 8 : 10),
                            Text(
                              'Enter the 6-digit OTP sent to ${widget.phoneNumber}',
                              style: TextStyle(
                                fontSize: isSmall ? 12 : 13,
                                color: Colors.grey.shade600,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isSmall ? 16 : 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                6,
                                (index) => SizedBox(
                                  width: isSmall ? 45 : 50,
                                  height: isSmall ? 45 : 50,
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _otpFocusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    onChanged: (value) => _handleOtpInput(value, index),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(
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
                                    ),
                                    style: TextStyle(
                                      fontSize: isSmall ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmall ? 18 : 24),
                            SizedBox(
                              width: double.infinity,
                              height: isSmall ? 50 : 56,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isOtpComplete && !_isLoading ? _verifyOtp : null,
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
                                              'Verify OTP',
                                              style: TextStyle(
                                                fontSize: isSmall ? 15 : 16,
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
                            SizedBox(height: isSmall ? 14 : 16),
                            Center(
                              child: Text(
                                'Didn\'t receive OTP? Resend in 30s',
                                style: TextStyle(
                                  fontSize: isSmall ? 12 : 13,
                                  color: Colors.grey.shade600,
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
    );
  }
}
