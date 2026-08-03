import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../main.dart' show authRepositoryProvider;

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
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _emailFocused = false;
  final FocusNode _emailFocus = FocusNode();
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
    _emailFocus.addListener(() {
      setState(() => _emailFocused = _emailFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final email = _emailController.text.trim();
      await authRepository.sendOtp(email);
      widget.onOtpPhoneChange(email);
      widget.onOtpSent();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.') && email.length > 5;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: AppTheme.saffron,
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
                  // Gradient background
                  Container(
                    width: double.infinity,
                    height: screenHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.saffron,
                          AppTheme.saffron.withOpacity(0.9),
                          const Color(0xFFE8860B),
                        ],
                      ),
                    ),
                  ),

                  // Decorative circles
                  Positioned(
                    top: -60,
                    left: -60,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    right: -80,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),

                  // Main content
                  Column(
                    children: [
                      // Header with logo
                      Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + (isSmall ? 12 : 20),
                          bottom: isSmall ? 16 : 24,
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
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: isSmall ? 100 : 120,
                                    height: isSmall ? 100 : 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmall ? 14 : 18),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'MahaMaintain\n',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmall ? 22 : 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Pro',
                                    style: TextStyle(
                                      color: const Color(0xFFFFD700),
                                      fontSize: isSmall ? 22 : 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmall ? 8 : 12),
                            Text(
                              'महाराष्ट्र का विश्वास',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: isSmall ? 11 : 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Form Card - Glassmorphic
                      Container(
                        margin: EdgeInsets.fromLTRB(
                          isSmall ? 12 : 16,
                          isSmall ? 16 : 20,
                          isSmall ? 12 : 16,
                          isSmall ? 12 : 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: AppTheme.saffron.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 16 : 20,
                          vertical: isSmall ? 16 : 20,
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
                              'Login to your account',
                              style: TextStyle(
                                fontSize: isSmall ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: isSmall ? 6 : 8),
                            Text(
                              "We'll send a secure OTP to your email",
                              style: TextStyle(
                                fontSize: isSmall ? 12 : 13,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: isSmall ? 16 : 20),

                            // Email Input Field - Modern Glassmorphic
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _emailFocused
                                      ? [
                                          AppTheme.saffron.withOpacity(0.08),
                                          AppTheme.saffron.withOpacity(0.04),
                                        ]
                                      : [
                                          Colors.grey.shade50,
                                          Colors.grey.shade50,
                                        ],
                                ),
                                border: Border.all(
                                  color: _emailFocused
                                      ? AppTheme.saffron.withOpacity(0.5)
                                      : Colors.grey.shade300,
                                  width: _emailFocused ? 2 : 1.5,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _emailFocused
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.saffron.withOpacity(0.2),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 2,
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'your.email@example.com',
                                    hintStyle: TextStyle(
                                      fontSize: isSmall ? 12 : 13,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: isSmall ? 12 : 14),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(right: 8),
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
                              ),
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
                              scale: _isValidEmail(_emailController.text) ? 1.02 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: SizedBox(
                                width: double.infinity,
                                height: isSmall ? 46 : 50,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap:
                                        _isValidEmail(_emailController.text) && !_isLoading
                                            ? _sendOtp
                                            : null,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.saffron.withOpacity(0.9),
                                            AppTheme.saffron.withOpacity(0.75),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.saffron.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, -2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isLoading
                                            ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation(
                                                    Colors.white.withOpacity(0.8),
                                                  ),
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Send OTP',
                                                    style: TextStyle(
                                                      fontSize: isSmall ? 13 : 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Icon(
                                                    Icons.arrow_forward,
                                                    color: Colors.white,
                                                    size: 16,
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
