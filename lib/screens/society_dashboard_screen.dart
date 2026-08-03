import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_footer.dart';
import 'emergency_sos_screen.dart';
import 'profile_screen.dart';
import 'ai_chat_screen.dart';

class SocietyDashboardScreen extends StatefulWidget {
  const SocietyDashboardScreen({Key? key}) : super(key: key);

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
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF2D1B4E), const Color(0xFF1A0F2E)],
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
                  // Camera icon
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
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
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Society\nDashboard',
                    style: TextStyle(
                      fontSize: isSmall ? 28 : 32,
                      fontWeight: FontWeight.bold,
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
                      color: Colors.white70,
                    ),
                  ),
                  // ID Card
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ID: MRP-2847',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
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
            ),
            const SizedBox(height: 16),

            // Content based on selected tab (footer handles navigation)
            if (_selectedTab == 0) ...[
              // Add Complaint Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
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
                      const Icon(Icons.arrow_forward, color: Colors.red, size: 20),
                    ],
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
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'View All →',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.teal,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'See All →',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildNoticeCard('Water Supply Shutdown — 18 Jun', 'Water supply will be off from 10 AM to 2 PM for tank cleaning.', 'Posted by Committee • Today', Colors.orange),
              _buildNoticeCard('AGM Meeting — 22 June 2026', 'Annual General Meeting at 7 PM in the clubhouse. All residents requested to attend...', '', Colors.teal),
              const SizedBox(height: 30),
            ] else if (_selectedTab == 1) ...[
              // Share Photo Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange,
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
              // Post Notice Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A4A7E),
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
              // Notices List
              _buildNoticeCard('Water Supply Shutdown — 18 Jun', 'Water supply will be off from 10 AM to 2 PM for tank cleaning.', 'Posted by Committee • Today', Colors.orange),
              _buildNoticeCard('AGM Meeting — 22 June 2026', 'Annual General Meeting at 7 PM in the clubhouse. All residents requested to attend...', '', Colors.teal),
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
              print('📱 Navigating to Profile Screen from Society Dashboard...');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              ).then((_) {
                print('✅ Returned from Profile Screen');
              });
              break;
          }
        },
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

}
