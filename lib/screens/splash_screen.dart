import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashComplete;

  const SplashScreen({required this.onSplashComplete, Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print('🚀 Splash Screen Initialized');
    print('📁 Trying to load: assets/images/maharashtra.png');
    Timer(const Duration(milliseconds: 3500), () {
      print('⏱️ Timer completed - navigating away from splash screen');
      widget.onSplashComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building splash screen...');
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF0A1128)),
            child: Opacity(
              opacity: 1.0,
              child: Image.asset(
                'assets/images/maharashtra.png',
                fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('❌ IMAGE LOAD ERROR: $error');
                print('📍 Stack trace: $stackTrace');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Image Failed to Load', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 10),
                      Text(error.toString(), style: const TextStyle(color: Colors.red, fontSize: 10)),
                    ],
                  ),
                );
              },
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                print('✅ Image loaded successfully! Frame: $frame');
                return child;
              },
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(
                    const Color(0xFFFF6F00).withOpacity(0.9),
                  ),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
