import 'package:flutter/material.dart';
import 'individual_dashboard_screen.dart';

/// Router screen that displays the Individual Dashboard for all users.
/// User role is passed to child screens to customize content (e.g., Society tab).
class DashboardScreen extends StatelessWidget {
  final String userRole;
  final VoidCallback onLogout;

  const DashboardScreen({
    required this.userRole,
    required this.onLogout,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🎯 DashboardScreen - userRole: $userRole');
    // All users see the same dashboard structure
    // User role is passed to customize content in tabs (e.g., Society tab)
    print('📱 Loading INDIVIDUAL Dashboard structure for all users');
    return IndividualDashboardScreen(
      onLogout: onLogout,
      userRole: userRole,
    );
  }
}
