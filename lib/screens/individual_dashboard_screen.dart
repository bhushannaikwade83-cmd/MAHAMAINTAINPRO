import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/dashboard_tab_controller.dart';
import '../widgets/custom_footer.dart';
import 'individual_home_screen.dart';
import 'search_list_screen.dart';
import 'ai_chat_screen.dart';
import 'society_screen.dart';
import 'society_tab_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';

/// Resolves which Society screen to show for tab 3.
///
/// Individual accounts always land on [SocietyScreen], which itself shows
/// the registration form, then a "pending admin approval" state once
/// submitted - there's no auto-unlock from just entering a phone number,
/// since a real society membership has to be approved by the Committee.
class _SocietyTabRoot extends StatelessWidget {
  final String userRole;

  const _SocietyTabRoot({required this.userRole});

  @override
  Widget build(BuildContext context) {
    if (userRole == 'society') {
      return const SocietyTabScreen();
    }
    return const SocietyScreen();
  }
}

/// Individual user dashboard screen - completely independent from society dashboard.
/// This screen manages its own state and navigation independently.
///
/// Each bottom-nav tab owns its own nested [Navigator], so pushing a screen
/// from within a tab (Visitor Gate, Parking, a booking detail, etc.) stays
/// inside that tab's stack instead of covering the whole dashboard - the
/// bottom nav bar stays visible no matter how deep the user navigates.
class IndividualDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String userRole;

  const IndividualDashboardScreen({
    required this.onLogout,
    this.userRole = 'individual',
    Key? key,
  }) : super(key: key);

  @override
  State<IndividualDashboardScreen> createState() => _IndividualDashboardScreenState();
}

class _IndividualDashboardScreenState extends State<IndividualDashboardScreen> {
  static const int _tabCount = 6;

  int _selectedTab = 0;
  late final List<Widget> _screens;
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(_tabCount, (_) => GlobalKey<NavigatorState>());
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    print('👤 User Role in IndividualDashboard: ${widget.userRole}');
    DashboardTabController.register((index) => setState(() => _selectedTab = index));
    _screens = [
      IndividualHomeScreen(                       // Tab 0: Home
        onNavigateToTab: (index) => setState(() => _selectedTab = index),
        userRole: widget.userRole,
      ),
      const SearchListScreen(),                   // Tab 1: Search
      const AiChatScreen(),                        // Tab 2: AI Chat
      _SocietyTabRoot(userRole: widget.userRole),   // Tab 3: Society
      const BookingsScreen(),                      // Tab 4: Bookings
      const ProfileScreen(),                        // Tab 5: Profile
    ];
  }

  @override
  void dispose() {
    DashboardTabController.unregister();
    super.dispose();
  }

  Future<bool> _handleBackButton() async {
    // If the current tab has something pushed on top, pop that first so
    // the bottom nav (and the tab's own screen) stays in place.
    final currentNavigator = _navigatorKeys[_selectedTab].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }

    // If on home page (tab 0), check double-tap to exit
    if (_selectedTab == 0) {
      final now = DateTime.now();
      if (_lastBackPressTime != null &&
          now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
        // Double tap within 2 seconds - exit app
        print('🚪 Double back tap - Exiting app');
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        }
        return false;
      }

      // First tap - show snackbar
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
      return false;
    }

    // If not on home, navigate to home page instead of closing
    print('🏠 Back button - Navigating to home');
    setState(() {
      _selectedTab = 0;
    });
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
          onNavItemTap: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          userRole: 'individual',
        ),
      ),
    );
  }
}
