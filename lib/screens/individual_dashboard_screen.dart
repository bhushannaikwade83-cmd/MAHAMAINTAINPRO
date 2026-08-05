import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../widgets/custom_footer.dart';
import 'individual_home_screen.dart';
import 'search_list_screen.dart';
import 'ai_chat_screen.dart';
import 'society_screen.dart';
import 'society_tab_screen.dart';
import 'society_dashboard_full_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';

/// Individual user dashboard screen - completely independent from society dashboard.
/// This screen manages its own state and navigation independently.
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
  int _selectedTab = 0;
  late List<Widget> _screens;
  String? _secretaryPhone;

  @override
  void initState() {
    super.initState();
    print('👤 User Role in IndividualDashboard: ${widget.userRole}');
    _loadSecretaryPhone();
  }

  Future<void> _loadSecretaryPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('secretary_phone');
    setState(() {
      _secretaryPhone = phone;
      _updateScreens();
    });
  }

  void _updateScreens() {
    _screens = [
      const IndividualHomeScreen(),           // Tab 0: Home
      const SearchListScreen(),       // Tab 1: Search
      const AiChatScreen(),           // Tab 2: AI Chat
      // Tab 3: Society - different based on user role and registration
      widget.userRole == 'society'
          ? SocietyTabScreen()        // Society member sees new dashboard
          : (_secretaryPhone != null && _secretaryPhone!.isNotEmpty)
              ? SocietyDashboardFullScreen(secretaryPhone: _secretaryPhone!)  // Individual with secretary phone sees dashboard
              : const SocietyScreen(),    // Individual sees register page
      const BookingsScreen(),         // Tab 4: Bookings
      const ProfileScreen(),          // Tab 5: Profile
    ];
  }

  Future<bool> _handleBackButton() async {
    // If on home page (tab 0), close the app
    if (_selectedTab == 0) {
      print('🚪 Back button on home - Exiting app');
      // On Android, exit the app
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      }
      return false;
    }

    // If not on home, navigate to home page instead of closing
    print('🏠 Back button - Navigating to home');
    setState(() {
      _selectedTab = 0;
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _updateScreens();
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        body: _screens[_selectedTab],
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
