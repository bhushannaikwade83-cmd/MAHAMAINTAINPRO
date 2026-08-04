import 'package:flutter/material.dart';
import '../widgets/custom_footer.dart';
import 'search_screen.dart';
import 'search_list_screen.dart';
import 'ai_chat_screen.dart';
import 'society_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';

/// Individual user dashboard screen - completely independent from society dashboard.
/// This screen manages its own state and navigation independently.
class IndividualDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const IndividualDashboardScreen({
    required this.onLogout,
    Key? key,
  }) : super(key: key);

  @override
  State<IndividualDashboardScreen> createState() => _IndividualDashboardScreenState();
}

class _IndividualDashboardScreenState extends State<IndividualDashboardScreen> {
  int _selectedTab = 0;

  // Each tab screen is independent - no shared state between dashboards
  final List<Widget> _screens = [
    const SearchScreen(),           // Tab 0: Home
    const SearchListScreen(),       // Tab 1: Search
    const AiChatScreen(),           // Tab 2: AI Chat
    const SocietyScreen(),          // Tab 3: Society
    const BookingsScreen(),         // Tab 4: Bookings
    const ProfileScreen(),          // Tab 5: Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
