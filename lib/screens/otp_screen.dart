import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';

import '../main.dart' show authRepositoryProvider;

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String? email;
  final Function(String?) onVerificationSuccess;
  final VoidCallback onBackPress;

  const OtpScreen({
    required this.phoneNumber,
    this.email,
    required this.onVerificationSuccess,
    required this.onBackPress,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  int _resendCountdown = 30;
  bool _canResend = false;
  bool _isVerifying = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _otpFocused = false;
  final FocusNode _otpFocus = FocusNode();

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
    _startResendCountdown();
    _otpFocus.addListener(() {
      setState(() => _otpFocused = _otpFocus.hasFocus);
    });
  }

  void _startResendCountdown() {
    _resendCountdown = 30;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendCountdown--);
      }
      return _resendCountdown > 0 && mounted;
    }).then((_) {
      if (mounted) setState(() => _canResend = true);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _animationController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    setState(() => _isVerifying = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.verifyOtp(phoneNumber, _otpController.text);
      widget.onVerificationSuccess(widget.email);
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  void _resendOtp() async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.resendOtp(phoneNumber);
    _otpController.clear();
    _startResendCountdown();
  }

  String get phoneNumber => widget.phoneNumber;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: AppTheme.saffron,
      body: Container(
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
        child: Stack(
          children: [
            // Decorative blobs
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
            // Content with scrolling
            SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + (isSmall ? 20 : 28),
                      left: isSmall ? 12 : 16,
                      right: isSmall ? 12 : 16,
                      bottom: isSmall ? 16 : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Premium Header
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
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: isSmall ? 100 : 120,
                                height: isSmall ? 100 : 120,
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
                                text: 'Verify\n',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmall ? 26 : 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              TextSpan(
                                text: 'OTP',
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
                        SizedBox(height: isSmall ? 28 : 36),
                        // Premium Form Card
                        Container(
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
                              Text(
                                'Enter OTP Code',
                                style: TextStyle(
                                  fontSize: isSmall ? 20 : 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.saffron,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              SizedBox(height: isSmall ? 8 : 10),
                              Text(
                                'Check your email for the 6-digit OTP',
                                style: TextStyle(
                                  fontSize: isSmall ? 12 : 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: isSmall ? 24 : 32),
                              // Premium OTP Input
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border: Border.all(
                                    color: _otpFocused
                                        ? AppTheme.saffron
                                        : Colors.grey.shade200,
                                    width: _otpFocused ? 2 : 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: _otpFocused
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.saffron.withOpacity(0.2),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: TextField(
                                  controller: _otpController,
                                  focusNode: _otpFocus,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmall ? 24 : 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 8,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '000000',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade300,
                                      letterSpacing: 8,
                                      fontSize: isSmall ? 24 : 28,
                                    ),
                                    filled: false,
                                    border: InputBorder.none,
                                    counterText: '',
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: isSmall ? 14 : 16,
                                    ),
                                  ),
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              SizedBox(height: isSmall ? 12 : 14),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${_otpController.text.length}/6',
                                  style: TextStyle(
                                    fontSize: isSmall ? 12 : 13,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmall ? 24 : 32),
                              AnimatedScale(
                                scale: _otpController.text.length == 6 ? 1.02 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: isSmall ? 50 : 56,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _otpController.text.length == 6 &&
                                              !_isVerifying
                                          ? _verifyOtp
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
                                          child: _isVerifying
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
                                                      'Verify & Login',
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
                              SizedBox(height: isSmall ? 20 : 24),
                              AnimatedOpacity(
                                opacity: 1,
                                duration: const Duration(milliseconds: 300),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Didn't receive OTP? ",
                                      style: TextStyle(
                                        fontSize: isSmall ? 13 : 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (_canResend)
                                      GestureDetector(
                                        onTap: _resendOtp,
                                        child: Text(
                                          'Resend',
                                          style: TextStyle(
                                            fontSize: isSmall ? 13 : 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.saffron,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        'Resend in ${_resendCountdown}s',
                                        style: TextStyle(
                                          fontSize: isSmall ? 13 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.saffron,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isSmall ? 12 : 16),
                              Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: widget.onBackPress,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.teal.withOpacity(0.2),
                                            AppTheme.teal.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.teal.withOpacity(0.4),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.teal.withOpacity(0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'Change Phone Number',
                                        style: TextStyle(
                                          fontSize: isSmall ? 13 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.teal,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
