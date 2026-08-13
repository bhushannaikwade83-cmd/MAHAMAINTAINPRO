import 'package:flutter/material.dart';
import '../widgets/custom_footer.dart';
import 'emergency_sos_screen.dart';
import 'profile_screen.dart';
import 'ai_chat_screen.dart';
import 'visitor_gate_screen.dart';
import 'parking_management_screen.dart';
import 'tenant_management_screen.dart';
import 'bills_maintenance_screen.dart';
import 'announcements_screen.dart';
import 'add_complaint_screen.dart';

class SocietyDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const SocietyDashboardScreen({
    required this.onLogout,
    Key? key,
  }) : super(key: key);

  @override
  State<SocietyDashboardScreen> createState() => _SocietyDashboardScreenState();
}

class _SocietyDashboardScreenState extends State<SocietyDashboardScreen> {
  int _selectedTab = 0;
  int _footerSelectedIndex = 3;

  final List<String> tabs = ['Dashboard', 'Photos', 'Notices'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with orange gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification and Back icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Society\nDashboard',
                    style: TextStyle(
                      fontSize: isSmall ? 28 : 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Society info
                  Text(
                    'Shri Ramdev Park CHS • Mira Road',
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // ID Card
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'ID: MRP-2847',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: List.generate(
                  tabs.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: Column(
                        children: [
                          Text(
                            tabs[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTab == index ? FontWeight.w700 : FontWeight.w500,
                              color: _selectedTab == index ? Colors.black87 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedTab == index)
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE67E22),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          else
                            Container(
                              height: 3,
                              color: Colors.transparent,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content based on selected tab
            if (_selectedTab == 0) ...[
              // Dashboard Tab Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildMenuCard(
                      '🚪',
                      'Visitor Gate',
                      'Manage visitor entries',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VisitorGateScreen()),
                      ).then((_) => setState(() {})),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      '🚗',
                      'Parking Management',
                      'Request guest parking',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ParkingManagementScreen()),
                      ).then((_) => setState(() {})),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      '👥',
                      'Tenant Management',
                      'Register tenants',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TenantManagementScreen()),
                      ).then((_) => setState(() {})),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      '📋',
                      'Bills & Maintenance',
                      'View maintenance bills',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BillsMaintenanceScreen()),
                      ).then((_) => setState(() {})),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      '📢',
                      'Announcements',
                      'View society notices',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
                      ).then((_) => setState(() {})),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Add Complaint Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddComplaintScreen()),
                  ).then((_) => setState(() {})),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5CC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE67E22), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67E22).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('📝', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Complaint',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Report an issue to management',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Color(0xFFE67E22), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Complaints & Tickets Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Complaints & Tickets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'View All →',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFE67E22),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildTicketCard('Water leakage — B Wing Corridor', 'Ticket #MRP-2847-3812 • 15 Jun', 'In Progress', Colors.amber),
              _buildTicketCard('Lift not working — Tower A', 'Ticket #MRP-2847-3791 • 10 Jun', 'Resolved ✓', Colors.green),
              _buildTicketCard('Gate motor making noise', 'Ticket #MRP-2847-3788 • 8 Jun', 'Resolved ✓', Colors.green),
              const SizedBox(height: 24),

              // Society Notices Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📣 Society Notices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'See All →',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFE67E22),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildNoticeCard('Water Supply Shutdown — 18 Jun', 'Water supply will be off from 10 AM to 2 PM for tank cleaning.', 'Posted by Committee • Today', Colors.orange),
              _buildNoticeCard('AGM Meeting — 22 June 2026', 'Annual General Meeting at 7 PM in the clubhouse. All residents requested to attend...', '', const Color(0xFFE67E22)),
              const SizedBox(height: 30),
            ] else if (_selectedTab == 1) ...[
              // Photos Tab Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('📷', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share a Photo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Upload from gallery or take new • Max 10 MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Photo Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    _buildPhotoCard('Ganesh Festival', '🎉', Colors.green.shade100),
                    _buildPhotoCard('Lift Repair Done', '🔧', Colors.blue.shade100),
                    _buildPhotoCard('Pool Cleaning', '🏊', Colors.cyan.shade100),
                    _buildPhotoCard('Society Day Celebr...', '🎊', Colors.purple.shade100),
                    _buildPhotoCard('Gate Motor Replaced', '🚪', Colors.amber.shade100),
                    _buildPhotoCard('Garden Beautification', '🌳', Colors.lime.shade100),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ] else if (_selectedTab == 2) ...[
              // Notices Tab Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C4A9E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('📌', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Post a Notice',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Committee only • Attach image or PDF',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Notices List with categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildCategoryNotice('URGENT NOTICE', '🔧', 'Water Tank Maintenance', 'Water supply will be off from 10 AM to 2 PM for tank cleaning.', Colors.orange, 'Today'),
                    const SizedBox(height: 12),
                    _buildCategoryNotice('EVENT', '🎉', 'AGM Meeting — 22 June 2026', 'Annual General Meeting at 7 PM in the clubhouse. All residents requested to attend...', const Color(0xFF1ABC9C), '2 days ago'),
                    const SizedBox(height: 12),
                    _buildCategoryNotice('AMENITY UPDATE', '🏊', 'Pool Maintenance Schedule', 'Pool will be closed on weekends for maintenance.', Colors.amber, '5 days ago'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
      bottomNavigationBar: CustomFooter(
        selectedIndex: _footerSelectedIndex,
        onNavItemTap: (index) {
          setState(() => _footerSelectedIndex = index);

          // Navigate based on footer selection
          switch (index) {
            case 0:
              // Home - stay on Society Dashboard
              break;
            case 1:
              // SOS
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencySosScreen(),
                ),
              );
              break;
            case 2:
              // AI Chat
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiChatScreen(),
                ),
              );
              break;
            case 3:
              // Profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
              break;
          }
        },
        userRole: 'society',
      ),
    );
  }

  Widget _buildTicketCard(String title, String subtitle, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard(String title, String description, String footer, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (footer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                footer,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryNotice(String category, String emoji, String title, String description, Color categoryColor, String timeAgo) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: categoryColor, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: categoryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(String title, String emoji, Color bgColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String emoji, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}
