import 'package:flutter/material.dart';
import 'individual_dashboard_screen.dart';
import 'society_dashboard_screen.dart';

/// Router screen that displays the appropriate dashboard based on user role.
/// This screen is never displayed directly - it immediately shows the correct dashboard.
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
    // Route to the appropriate independent dashboard based on user role
    // Each dashboard is completely independent with its own state
    print('🎯 DashboardScreen - userRole: $userRole');
    if (userRole == 'society') {
      print('🏢 Loading SOCIETY Dashboard');
      return SocietyDashboardScreen(onLogout: onLogout);
    } else {
      // Individual/user dashboard
      print('👤 Loading INDIVIDUAL Dashboard');
      return IndividualDashboardScreen(onLogout: onLogout);
    }
  }
}
