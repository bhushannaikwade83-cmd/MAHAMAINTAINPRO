import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/role_access/models/user_role.dart';
import '../../features/role_access/services/permission_service.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../widgets/coming_soon_screen.dart';
import 'route_names.dart';

/// A permission required to enter a given route. Screens not listed here
/// are accessible to any authenticated user.
final Map<String, Permission> _routePermissions = {
  RouteNames.userManagement: Permission.manageUsers,
  RouteNames.leads: Permission.manageOwnLeads,
  RouteNames.customers: Permission.manageCustomers,
  RouteNames.societies: Permission.manageSociety,
};

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthLoading = authState.isLoading;
      final goingToAuthScreen = [
        RouteNames.login,
        RouteNames.otpLogin,
        RouteNames.register,
      ].contains(state.matchedLocation);

      if (isAuthLoading) return null; // stay on splash while resolving

      if (!isLoggedIn && !goingToAuthScreen && state.matchedLocation != RouteNames.splash) {
        return RouteNames.login;
      }
      if (isLoggedIn && (goingToAuthScreen || state.matchedLocation == RouteNames.splash)) {
        return RouteNames.dashboard;
      }

      // Role/permission guard for protected sections.
      final requiredPermission = _routePermissions[state.matchedLocation];
      if (requiredPermission != null) {
        final appUser = ref.read(currentAppUserProvider).valueOrNull;
        if (appUser != null && !PermissionService.can(appUser.role, requiredPermission)) {
          return RouteNames.dashboard;
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: RouteNames.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RouteNames.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RouteNames.otpLogin, builder: (context, state) => const OtpScreen()),
      GoRoute(path: RouteNames.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: RouteNames.dashboard, builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: RouteNames.leads,
        builder: (context, state) => const ComingSoonScreen(title: 'Lead Management'),
      ),
      GoRoute(
        path: RouteNames.customers,
        builder: (context, state) => const ComingSoonScreen(title: 'Customer Master'),
      ),
      GoRoute(
        path: RouteNames.societies,
        builder: (context, state) => const ComingSoonScreen(title: 'Society Master'),
      ),
      GoRoute(
        path: RouteNames.serviceRequests,
        builder: (context, state) => const ComingSoonScreen(title: 'Service Requests'),
      ),
      GoRoute(
        path: RouteNames.userManagement,
        builder: (context, state) => const ComingSoonScreen(title: 'User Management'),
      ),
    ],
  );
});
