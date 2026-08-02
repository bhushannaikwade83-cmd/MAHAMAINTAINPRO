import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  final Function(String) onRoleSelected;

  const RoleSelectionScreen({
    required this.onRoleSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _selectedRole;

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
    _animationController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() => _selectedRole = role);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onRoleSelected(role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            children: [
              // Soft light gradient background
              Container(
                width: double.infinity,
                height: screenHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.white,
                      Colors.white,
                    ],
                  ),
                ),
              ),

              // Decorative blobs
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.saffron.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.teal.withOpacity(0.05),
                  ),
                ),
              ),

              SingleChildScrollView(
                child: Column(
                  children: [
                    // Header with gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppTheme.saffron, AppTheme.saffronDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.saffron.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + (isSmall ? 24 : 40),
                        bottom: isSmall ? 48 : 64,
                        left: 24,
                        right: 24,
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
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  'images/logo.jpeg',
                                  width: isSmall ? 140 : 180,
                                  height: isSmall ? 140 : 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: isSmall ? 140 : 180,
                                      height: isSmall ? 140 : 180,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.1),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '🏢',
                                          style: TextStyle(
                                            fontSize: isSmall ? 60 : 80,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmall ? 20 : 28),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'MahaMaintain\n',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmall ? 26 : 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Pro',
                                  style: TextStyle(
                                    color: const Color(0xFFFFD700),
                                    fontSize: isSmall ? 26 : 32,
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
                              color: Colors.white70,
                              fontSize: isSmall ? 13 : 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Role Selection Content
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 16 : 24,
                        vertical: isSmall ? 32 : 48,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Who are you?',
                            style: TextStyle(
                              fontSize: isSmall ? 26 : 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: isSmall ? 8 : 12),
                          Text(
                            'Choose your role to get started',
                            style: TextStyle(
                              fontSize: isSmall ? 13 : 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          SizedBox(height: isSmall ? 40 : 56),
                          // Individual Customer Card
                          _buildRoleCard(
                            title: 'I\'m an Individual',
                            subtitle: 'Book services for your home',
                            emoji: '👤',
                            role: 'individual',
                            neonColor: AppTheme.neonCyan,
                            isSelected: _selectedRole == 'individual',
                            isSmall: isSmall,
                            onTap: () => _selectRole('individual'),
                          ),
                          SizedBox(height: isSmall ? 16 : 20),
                          // Society Card
                          _buildRoleCard(
                            title: 'I\'m from Society',
                            subtitle: 'Manage society services',
                            emoji: '🏘️',
                            role: 'society',
                            neonColor: AppTheme.neonGreen,
                            isSelected: _selectedRole == 'society',
                            isSmall: isSmall,
                            onTap: () => _selectRole('society'),
                          ),
                          SizedBox(height: isSmall ? 32 : 48),
                          Text(
                            'By continuing, you agree to our Terms & Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmall ? 11 : 12,
                              color: AppTheme.textTertiary,
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
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required String emoji,
    required String role,
    required Color neonColor,
    required bool isSelected,
    required bool isSmall,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    neonColor.withOpacity(0.14),
                    neonColor.withOpacity(0.06),
                  ],
                )
              : LinearGradient(
                  colors: [Colors.white, Colors.white],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? neonColor : AppTheme.borderColor,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: neonColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          vertical: isSmall ? 22 : 26,
          horizontal: isSmall ? 18 : 24,
        ),
        child: Row(
          children: [
            // Emoji Container with glow effect
            Container(
              width: isSmall ? 64 : 72,
              height: isSmall ? 64 : 72,
              decoration: BoxDecoration(
                color: isSelected ? neonColor.withOpacity(0.15) : AppTheme.bgLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? neonColor.withOpacity(0.4) : AppTheme.borderColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: isSmall ? 32 : 36,
                  ),
                ),
              ),
            ),
            SizedBox(width: isSmall ? 16 : 20),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmall ? 17 : 19,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: isSmall ? 6 : 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 13,
                      color: isSelected ? Colors.black54 : AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow Icon with animation
            AnimatedScale(
              scale: isSelected ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: isSmall ? 48 : 52,
                height: isSmall ? 48 : 52,
                decoration: BoxDecoration(
                  color: isSelected ? neonColor.withOpacity(0.15) : AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? neonColor.withOpacity(0.4) : AppTheme.borderColor,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.arrow_forward,
                    color: isSelected ? neonColor : AppTheme.textTertiary,
                    size: isSmall ? 22 : 24,
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
