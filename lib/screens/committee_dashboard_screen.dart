import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../config/app_theme.dart';
import '../widgets/custom_footer.dart';
import 'society_tab_screen.dart';

/// Dedicated dashboard shell for the Society Committee role.
///
/// Committee members only manage their society - they don't book personal
/// services, so this deliberately does NOT reuse IndividualDashboardScreen
/// (Home/Search/AI Chat/Bookings are all individual-customer features).
/// Just the society dashboard (with admin actions unlocked) and a profile.
///
/// Uses the same nested-Navigator-per-tab pattern as IndividualDashboardScreen
/// so the bottom nav stays visible no matter how deep the committee member
/// navigates (Bills, Announcements, Visitor Gate, etc.).
class CommitteeDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const CommitteeDashboardScreen({required this.onLogout, Key? key}) : super(key: key);

  @override
  State<CommitteeDashboardScreen> createState() => _CommitteeDashboardScreenState();
}

class _CommitteeDashboardScreenState extends State<CommitteeDashboardScreen> {
  static const int _tabCount = 2;

  int _selectedTab = 0;
  late final List<Widget> _screens;
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(_tabCount, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    _screens = [
      const SocietyTabScreen(isCommittee: true), // Tab 0: Society Dashboard
      _CommitteeProfileScreen(onLogout: widget.onLogout), // Tab 1: Profile
    ];
  }

  Future<bool> _handleBackButton() async {
    final currentNavigator = _navigatorKeys[_selectedTab].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }

    if (_selectedTab == 0) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      }
      return false;
    }

    setState(() => _selectedTab = 0);
    return false;
  }

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => _screens[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedTab,
          children: List.generate(_tabCount, _buildTabNavigator),
        ),
        bottomNavigationBar: CustomFooter(
          selectedIndex: _selectedTab,
          onNavItemTap: (index) => setState(() => _selectedTab = index),
          userRole: 'committee',
        ),
      ),
    );
  }
}

class _CommitteeProfileScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const _CommitteeProfileScreen({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3ED),
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('👤 Committee Profile'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.saffron.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🗳️', style: TextStyle(fontSize: 40))),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Society Committee',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Shri Ramdev Park CHS',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: AppTheme.saffron, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'You can add bills, post announcements, and manage everything on the society dashboard.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onLogout();
                          },
                          child: const Text('Logout', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
