import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'society_details_screen.dart';

class IndividualSignupScreen extends StatefulWidget {
  final VoidCallback? onBackPress;

  const IndividualSignupScreen({this.onBackPress, Key? key}) : super(key: key);

  @override
  State<IndividualSignupScreen> createState() => _IndividualSignupScreenState();
}

class _IndividualSignupScreenState extends State<IndividualSignupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isValidForm() {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().length == 10 &&
        _emailController.text.trim().contains('@') &&
        _addressController.text.trim().isNotEmpty;
  }

  void _proceedToSocietyDetails() {
    if (!_isValidForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SocietyDetailsScreen(
          individualName: _nameController.text.trim(),
          individualPhone: _phoneController.text.trim(),
          individualEmail: _emailController.text.trim(),
          individualAddress: _addressController.text.trim(),
        ),
      ),
    );
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
                            if (widget.onBackPress != null)
                              GestureDetector(
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
                              )
                            else
                              const SizedBox(width: 40),
                            Text(
                              'Sign Up',
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
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: isSmall ? 16 : 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.saffron,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: isSmall ? 14 : 16),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                icon: Icons.person_outline,
                                isSmall: isSmall,
                              ),
                              SizedBox(height: isSmall ? 12 : 14),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                hint: '10 digit mobile number',
                                icon: Icons.phone_outlined,
                                isSmall: isSmall,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                              ),
                              SizedBox(height: isSmall ? 12 : 14),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                hint: 'your.email@example.com',
                                icon: Icons.email_outlined,
                                isSmall: isSmall,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: isSmall ? 12 : 14),
                              _buildTextField(
                                controller: _addressController,
                                label: 'Residential Address',
                                hint: 'Enter your address',
                                icon: Icons.location_on_outlined,
                                isSmall: isSmall,
                                maxLines: 3,
                              ),
                              SizedBox(height: isSmall ? 18 : 24),
                              SizedBox(
                                width: double.infinity,
                                height: isSmall ? 50 : 56,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isValidForm() && !_isLoading
                                        ? _proceedToSocietyDetails
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
                                                'Continue to Society Details →',
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
