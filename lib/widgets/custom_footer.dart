import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CustomFooter extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavItemTap;
  final String? userRole; // 'vendor' or 'user'

  const CustomFooter({
    required this.selectedIndex,
    required this.onNavItemTap,
    this.userRole = 'user',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: userRole == 'vendor'
            ? [
                // Vendor tabs: Home, Societies, Earnings, Profile
                _buildNavItem(context, Icons.home_rounded, 'Home', 0),
                _buildNavItem(context, Icons.apartment_rounded, 'Societies', 1),
                _buildNavItem(context, Icons.monetization_on_rounded, 'Earnings', 2),
                _buildNavItem(context, Icons.person_rounded, 'Profile', 3),
              ]
            : [
                // User tabs: Home, Search, AI Chat, Society, Bookings, Profile
                _buildNavItem(context, Icons.home_rounded, 'Home', 0),
                _buildNavItem(context, Icons.search_rounded, 'Search', 1),
                _buildNavItem(context, Icons.smart_toy_rounded, 'AI Chat', 2),
                _buildNavItem(context, Icons.apartment_rounded, 'Society', 3),
                _buildNavItem(context, Icons.assignment_rounded, 'Bookings', 4),
                _buildNavItem(context, Icons.person_rounded, 'Profile', 5),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, int index) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onNavItemTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isActive ? 36 : 24,
            height: isActive ? 26 : 24,
            alignment: Alignment.center,
            decoration: isActive
                ? BoxDecoration(
                    color: AppTheme.saffron.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  )
                : null,
            child: Icon(
              icon,
              size: 19,
              color: isActive ? AppTheme.saffron : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isActive ? AppTheme.saffron : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
