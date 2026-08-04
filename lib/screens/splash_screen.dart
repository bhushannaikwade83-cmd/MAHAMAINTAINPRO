import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashComplete;

  const SplashScreen({
    required this.onSplashComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Navigate to login after 3.5 seconds
    Timer(const Duration(milliseconds: 3500), () {
      widget.onSplashComplete();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      body: Stack(
        children: [
          // Deep Navy Background with subtle gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A1128),
                  const Color(0xFF121212).withOpacity(0.95),
                  const Color(0xFF0F0F1E),
                ],
              ),
            ),
          ),

          // Decorative blob - top right
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6F00).withOpacity(0.05),
              ),
            ),
          ),

          // Decorative blob - bottom left
          Positioned(
            bottom: -120,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withOpacity(0.03),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              // Top Section (Empty/Transparent for safe area)
              SizedBox(height: screenHeight * 0.15),

              // Center Section (Main Calligraphy)
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Icon/Symbol (optional - you can replace with your symbol)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF6F00).withOpacity(0.15),
                              border: Border.all(
                                color: const Color(0xFFFF6F00).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '🙏',
                                style: TextStyle(fontSize: 40),
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Main Calligraphy - Vishwas (विश्वास)
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'विश्वास',
                                  style: const TextStyle(
                                    color: Color(0xFFFF6F00),
                                    fontSize: 72,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Subtitle - Maharashtra-cha (महाराष्ट्राचा)
                          Text(
                            'महाराष्ट्राचा',
                            style: TextStyle(
                              color: const Color(0xFFFFD700),
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Section (Tagline & Loader)
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Tagline
                      Text(
                        '"महाराष्ट्राचा स्वतःचा डिजिटल मंच"',
                        style: TextStyle(
                          color: const Color(0xFFE0E0E0),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // Loading Spinner
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            const Color(0xFFFF6F00).withOpacity(0.8),
                          ),
                          strokeWidth: 2.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Version
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: const Color(0xFFE0E0E0).withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
