import 'package:go_router/go_router.dart';
import '../repositories/auth_repository.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/dashboard_screen.dart';

class AppRouter {
  static String? _currentPhoneForOtp;
  // Role is now assigned by admin panel, not selected by user
  static String _userRole = 'individual'; // Default role from admin panel

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
            onOtpPhoneChange: (phone) {
              _currentPhoneForOtp = phone;
            },
            onBackPress: null, // No back button - admin assigns role
          ),
        ),
        GoRoute(
          path: '/otp',
          name: 'otp',
          builder: (context, state) => OtpScreen(
            phoneNumber: _currentPhoneForOtp ?? '+91',
            onVerificationSuccess: () {
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
