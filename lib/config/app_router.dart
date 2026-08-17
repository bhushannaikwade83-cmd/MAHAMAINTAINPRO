import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/dashboard_screen.dart';

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
      redirect: (context, state) async {
        final isAuthenticated = authRepository.isAuthenticated();
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/otp';

        // Check if user has a saved login session
        final prefs = await SharedPreferences.getInstance();
        final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        final userPhone = prefs.getString('userPhone');

        // If on login/OTP screens, stay there
        if (isLoggingIn) {
          return null;
        }

        // If has saved session, go to dashboard
        if (isLoggedIn && userPhone != null) {
          return '/dashboard';
        }

        // If authenticated, go to dashboard
        if (isAuthenticated) {
          return '/dashboard';
        }

        // If not authenticated, go to login
        return '/login';
      },
      routes: [
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
              context.go('/otp');
            },
            onOtpPhoneChange: (email) {
              _currentPhoneForOtp = email;
              _currentEmailForOtp = email; // Store email for role detection
            },
            onBackPress: null, // No back button - admin assigns role
          ),
        ),
        GoRoute(
          path: '/otp',
          name: 'otp',
          builder: (context, state) => OtpScreen(
            phoneNumber: _currentPhoneForOtp ?? '+91',
            email: _currentEmailForOtp,
            onVerificationSuccess: (email) {
              // Detect if user is from society based on demo email
              print('🔍 OTP Verification - Email: $email');
              print('📧 Email lowercase: ${email?.toLowerCase()}');
              print('📋 Society emails: $_societyDemoEmails');
              final lowerEmail = email?.toLowerCase();
              if (_committeeDemoEmails.contains(lowerEmail)) {
                print('✅ COMMITTEE USER DETECTED');
                setUserRole('committee');
              } else if (_securityGuardDemoEmails.contains(lowerEmail)) {
                print('✅ SECURITY GUARD USER DETECTED');
                setUserRole('security_guard');
              } else if (_societyDemoEmails.contains(lowerEmail)) {
                print('✅ SOCIETY USER DETECTED');
                setUserRole('society');
              } else {
                print('👤 INDIVIDUAL USER DETECTED');
                setUserRole('individual');
              }
              print('🎯 Final role set to: $_userRole');
              context.go('/dashboard');
            },
            onBackPress: () {
              context.go('/login');
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
      initialLocation: '/login',
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
