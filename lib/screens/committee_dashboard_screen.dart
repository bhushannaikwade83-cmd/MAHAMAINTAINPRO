import 'package:flutter/material.dart';
import 'society_dashboard.dart';

/// Dedicated dashboard shell for the Society Committee role.
///
/// Committee members only manage their society - they don't book personal
/// services. Shows the Society Dashboard with admin features unlocked.
/// No footer navigation - full screen dedicated to society management.
class CommitteeDashboardScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const CommitteeDashboardScreen({required this.onLogout, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SocietyDashboardScreen(isCommittee: true);
  }
}
