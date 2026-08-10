import 'package:flutter/material.dart';
import 'individual_dashboard_screen.dart';
import 'security_guard_dashboard_screen.dart';
import 'committee_dashboard_screen.dart';

/// Router screen that displays the correct dashboard shell for the user's role.
/// Individual/Society share the tabbed consumer dashboard (Home, Search, AI
/// Chat, Society, Bookings, Profile). Committee and Security Guard each get
/// their own dedicated, much narrower shell - they manage the society or
/// gate, they don't book personal services, so none of the consumer tabs
/// belong in their app at all.
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
    if (userRole == 'committee') {
      return CommitteeDashboardScreen(onLogout: onLogout);
    }
    return IndividualDashboardScreen(
      onLogout: onLogout,
      userRole: userRole,
    );
  }
}
