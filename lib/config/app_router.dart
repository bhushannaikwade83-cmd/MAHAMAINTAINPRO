import 'package:go_router/go_router.dart';
import '../repositories/auth_repository.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/dashboard_screen.dart';

class AppRouter {
  static String? _currentPhoneForOtp;
  static String? _currentEmailForOtp;
  // Role is now assigned by admin panel, not selected by user
  static String _userRole = 'individual'; // Default role from admin panel

  // Demo emails for society users
  static const List<String> _societyDemoEmails = [
    'society@maha.com',
    'admin@society.com',
    'societyadmin@demo.com',
  ];

  static GoRouter createRouter(SupabaseAuthRepository authRepository) {
    return GoRouter(
      redirect: (context, state) async {
        final isAuthenticated = authRepository.isAuthenticated();
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/otp';

        // If on login/OTP screens, stay there
        if (isLoggingIn) {
          return null;
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
              if (_societyDemoEmails.contains(email?.toLowerCase())) {
                setUserRole('society');
              } else {
                setUserRole('individual');
              }
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
