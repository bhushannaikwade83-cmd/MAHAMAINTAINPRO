import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/otp_verification_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/mpin_login_screen.dart';
import '../screens/mpin_setup_screen.dart';

class AppRouter {
  static String? _currentPhoneForOtp;
  static String? _currentEmailForOtp;
  // Each session's role is determined based on email during OTP verification
  // This prevents state bleeding between individual and society dashboards
  static String _userRole = 'individual'; // Default role, updated on login

  // Demo emails for society users - used to determine user type
  static const List<String> _societyDemoEmails = [
    'society@gmail.com',      // Main society demo button
    'society@maha.com',
    'admin@society.com',
    'societyadmin@demo.com',
  ];

  // Demo emails for society committee members
  static const List<String> _committeeDemoEmails = [
    'committee@gmail.com',    // Main committee demo button
    'committee@maha.com',
    'committee@society.com',
  ];

  // Demo emails for security guards
  static const List<String> _securityGuardDemoEmails = [
    'guard@gmail.com',        // Main security guard demo button
    'guard@maha.com',
    'security@society.com',
  ];

  static GoRouter createRouter(SupabaseAuthRepository authRepository) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) async {
        try {
          // Avoid redirects for known routes during initialization
          if (state.matchedLocation == '/login' ||
              state.matchedLocation == '/otp' ||
              state.matchedLocation == '/mpin-login' ||
              state.matchedLocation == '/mpin-setup' ||
              state.matchedLocation == '/dashboard' ||
              state.matchedLocation == '/') {

            // Check if user has a saved login session
            final prefs = await SharedPreferences.getInstance();
            final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
            final isAuthenticated = authRepository.isAuthenticated();

            // Redirect to dashboard if user is logged in
            if ((isLoggedIn || isAuthenticated) && state.matchedLocation != '/dashboard') {
              return '/dashboard';
            }

            // Redirect to login if not logged in and trying to access dashboard
            if (!isLoggedIn && !isAuthenticated && state.matchedLocation == '/dashboard') {
              return '/login';
            }
          }
          return null; // No redirect
        } catch (e) {
          print('Router redirect error: $e');
          return '/login'; // Default to login on error
        }
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => SplashScreen(
            onSplashComplete: () {
              context.go('/login');
            },
          ),
        ),
        GoRoute(
          path: '/',
          name: 'home',
          redirect: (context, state) => '/login',
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => LoginScreen(
            onOtpSent: () {
              // Router will determine whether to go to M-PIN or OTP
              // based on the phone number stored
              _currentPhoneForOtp != null
                ? context.go('/mpin-login')
                : context.go('/otp');
            },
            onOtpPhoneChange: (phone) {
              _currentPhoneForOtp = phone;
              _currentEmailForOtp = phone;
            },
            onBackPress: null,
          ),
        ),
        GoRoute(
          path: '/otp',
          name: 'otp',
          builder: (context, state) => OtpVerificationScreen(
            phoneNumber: _currentPhoneForOtp ?? '+91',
            onBackPress: () {
              context.go('/login');
            },
          ),
        ),
        GoRoute(
          path: '/mpin-login',
          name: 'mpin-login',
          builder: (context, state) => MpinLoginScreen(
            phoneNumber: _currentPhoneForOtp ?? '+91',
            onVerificationSuccess: () {
              context.go('/dashboard');
            },
            onUseOtpInstead: (phone) {
              _currentPhoneForOtp = phone;
              context.go('/otp');
            },
            onBackPress: () {
              context.go('/login');
            },
          ),
        ),
        GoRoute(
          path: '/mpin-setup',
          name: 'mpin-setup',
          builder: (context, state) => MpinSetupScreen(
            onMpinSet: () {
              context.go('/dashboard');
            },
          ),
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => DashboardScreen(
            userRole: _userRole,
            onLogout: () {
              context.go('/login');
            },
          ),
        ),
      ],
      errorBuilder: (context, state) => const RouteErrorPage(),
    );
  }

  // Method to set user role from admin panel
  static void setUserRole(String role) {
    _userRole = role;
  }

  // Method to get current user role
  static String getUserRole() {
    return _userRole;
  }
}

class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Route not found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
