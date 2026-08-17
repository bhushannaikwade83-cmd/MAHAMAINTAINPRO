import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../config/app_theme.dart';
import 'individual_signup_screen.dart';

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
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _resendCountdown = 30;
  Timer? _resendTimer;
  bool _canResend = false;

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
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _canResend = false;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _resendOtp() async {
    if (!_canResend) return;

    try {
      final response = await _sendOtpApi(widget.phoneNumber);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _startResendTimer();
        // Clear fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to resend OTP'),
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
    }
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
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 4;

  void _handleOtpInput(String value, int index) {
    if (value.length > 1) {
      _otpControllers[index].text = value[value.length - 1];
      return;
    }

    if (value.isNotEmpty && index < 3) {
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

      final response = await _verifyOtpApi(widget.phoneNumber, otp);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Check if user already exists
        final userExists = await _checkUserExists(widget.phoneNumber);

        if (userExists) {
          // Existing user - save session and go to dashboard
          await _saveLoginSession(widget.phoneNumber);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome back!'),
              backgroundColor: Colors.blue,
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            context.go('/dashboard');
          });
        } else {
          // New user - go to signup
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualSignUpScreen(
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'OTP verification failed'),
            backgroundColor: Colors.red,
          ),
        );
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
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<bool> _checkUserExists(String phoneNumber) async {
    try {
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/check-user.php');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking user: $e');
      return false;
    }
  }

  Future<void> _saveLoginSession(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userPhone', phoneNumber);
      await prefs.setString('userType', 'individual');
      await prefs.setString('loginTime', DateTime.now().toIso8601String());
      debugPrint('✅ Login session saved');
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
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
            child: Stack(
              children: [
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
                Column(
                  children: [
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: isSmall ? 100 : 120,
                              height: isSmall ? 100 : 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: isSmall ? 14 : 18),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Verify\n',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmall ? 28 : 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                TextSpan(
                                  text: 'OTP',
                                  style: TextStyle(
                                    color: const Color(0xFFFFD700),
                                    fontSize: isSmall ? 28 : 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(
                        isSmall ? 12 : 16,
                        isSmall ? 16 : 20,
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
                            'Enter OTP Code',
                            style: TextStyle(
                              fontSize: isSmall ? 16 : 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.saffron,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: isSmall ? 8 : 10),
                          Text(
                            'Check your SMS for the 4-digit OTP',
                            style: TextStyle(
                              fontSize: isSmall ? 12 : 13,
                              color: Colors.grey.shade600,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: isSmall ? 18 : 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              4,
                              (index) => SizedBox(
                                width: isSmall ? 55 : 65,
                                height: isSmall ? 55 : 65,
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
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: AppTheme.saffron,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: isSmall ? 22 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmall ? 20 : 28),
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
                                              valueColor: AlwaysStoppedAnimation(Colors.white),
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Verify & Login',
                                                style: TextStyle(
                                                  fontSize: isSmall ? 15 : 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmall ? 14 : 16),
                          Center(
                            child: Text(
                              _canResend
                                  ? 'Didn\'t receive OTP? Resend now'
                                  : 'Didn\'t receive OTP? Resend in ${_resendCountdown}s',
                              style: TextStyle(
                                fontSize: isSmall ? 12 : 13,
                                color: _canResend ? AppTheme.saffron : Colors.grey.shade600,
                                fontWeight: _canResend ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_canResend)
                            SizedBox(height: isSmall ? 12 : 14),
                          if (_canResend)
                            SizedBox(
                              width: double.infinity,
                              height: isSmall ? 42 : 48,
                              child: ElevatedButton(
                                onPressed: _resendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  'Change Phone Number',
                                  style: TextStyle(
                                    fontSize: isSmall ? 13 : 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
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
    );
  }
}
