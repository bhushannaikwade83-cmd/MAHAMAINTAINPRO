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
                              'महाराष्ट्र का विश्वास • Premium Services',
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
                              controller: _emailController,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'your.email@example.com',
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
                              scale: _isValidEmail(_emailController.text) ? 1.02 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: SizedBox(
                                width: double.infinity,
                                height: isSmall ? 50 : 56,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap:
                                        _isValidEmail(_emailController.text) && !_isLoading
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
                            SizedBox(height: isSmall ? 16 : 20),

                            // Premium Demo Section
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmall ? 14 : 16,
                                vertical: isSmall ? 14 : 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.blue.shade50.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🎯 Quick Demo Access',
                                    style: TextStyle(
                                      fontSize: isSmall ? 13 : 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.blue.shade700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(height: isSmall ? 10 : 12),
                                  // Individual Demo Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: isSmall ? 42 : 46,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _emailController.text = 'member@gmail.com';
                                        setState(() {});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        '👤 Individual Demo',
                                        style: TextStyle(
                                          fontSize: isSmall ? 12 : 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmall ? 10 : 12),
                                  // Society Demo Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: isSmall ? 42 : 46,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _emailController.text = 'society@gmail.com';
                                        setState(() {});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.saffron,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        '🏢 Society Demo',
                                        style: TextStyle(
                                          fontSize: isSmall ? 12 : 13,
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
