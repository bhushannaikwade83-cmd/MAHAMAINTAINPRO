import 'package:flutter/material.dart';
import 'individual_dashboard_screen.dart';
import 'security_guard_dashboard_screen.dart';

/// Router screen that displays the correct dashboard shell for the user's role.
/// Individual/Society share the tabbed consumer dashboard (Home, Search, AI
/// Chat, Society, Bookings, Profile). Security Guard gets their own dedicated shell.
/// Committee members use the individual dashboard with committee features enabled.
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
    if (userRole == 'security_guard') {
      return SecurityGuardDashboardScreen(onLogout: onLogout);
    }
    return IndividualDashboardScreen(
      onLogout: onLogout,
      userRole: userRole,
    );
  }
}
