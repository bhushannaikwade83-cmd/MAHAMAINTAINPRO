import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'society_registration_screen.dart';
import 'emergency_sos_screen.dart';

class SocietyScreen extends StatefulWidget {
  const SocietyScreen({Key? key}) : super(key: key);

  @override
  State<SocietyScreen> createState() => _SocietyScreenState();
}

class _SocietyScreenState extends State<SocietyScreen> {
  bool _isSocietyRegistered = false;
  int _selectedTab = 0;
  final List<String> _tabs = ['Dashboard', 'Photos', 'Notices'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    // If society not registered, show registration prompt
    if (!_isSocietyRegistered) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.saffron, AppTheme.saffronDark],
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + (isSmall ? 8 : 10),
                  left: 0,
                  right: 0,
                  bottom: isSmall ? 12 : 14,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Society Hub 🏢',
                        style: TextStyle(
                          fontSize: isSmall ? 24 : 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: isSmall ? 2 : 4),
                      Text(
                        'Register to access community features',
                        style: TextStyle(
                          fontSize: isSmall ? 12 : 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Unregistered State
              Padding(
                padding: EdgeInsets.all(isSmall ? 16 : 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: isSmall ? 12 : 16),
                    // Lock Icon
                    Container(
                      width: isSmall ? 80 : 100,
                      height: isSmall ? 80 : 100,
                      decoration: BoxDecoration(
                        color: AppTheme.saffron.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.lock,
                        size: isSmall ? 40 : 50,
                        color: AppTheme.saffron,
                      ),
                    ),
                    SizedBox(height: isSmall ? 16 : 20),

                    Text(
                      'Society Not Registered',
                      style: TextStyle(
                        fontSize: isSmall ? 19 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: isSmall ? 8 : 10),

                    Text(
                      'Register your society to unlock all community features like visitor gate management, parking, announcements, and more.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmall ? 13 : 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: isSmall ? 20 : 24),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: isSmall ? 48 : 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SocietyRegistrationScreen(
                                onRegistrationComplete: () {
                                  setState(() => _isSocietyRegistered = true);
                                },
                              ),
                            ),
                          );
                          if (result == true) {
                            setState(() => _isSocietyRegistered = true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.saffron,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Register Society Now',
                          style: TextStyle(
                            fontSize: isSmall ? 14 : 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 10 : 12),

                    // Complaint Button (Always Available)
                    SizedBox(
                      width: double.infinity,
                      height: isSmall ? 48 : 50,
                      child: OutlinedButton(
                        onPressed: () {
                          final message = Uri.encodeComponent('Hi, I have a complaint regarding our society.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening WhatsApp...'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green.shade600, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '💬 File Complaint via WhatsApp',
                          style: TextStyle(
                            fontSize: isSmall ? 13 : 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 10 : 12),
                    // SOS Button
                    SizedBox(
                      width: double.infinity,
                      height: isSmall ? 48 : 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmergencySosScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade600, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '🚨 Emergency SOS (Always Available)',
                          style: TextStyle(
                            fontSize: isSmall ? 13 : 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Orange Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.saffron, AppTheme.saffronDark],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + (isSmall ? 8 : 10),
                left: 0,
                right: 0,
                bottom: isSmall ? 12 : 16,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 12, vertical: isSmall ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: isSmall ? 28 : 32,
                                  height: isSmall ? 28 : 32,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: isSmall ? 6 : 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YOUR SERVICES',
                                    style: TextStyle(
                                      fontSize: isSmall ? 8 : 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Personal Services',
                                    style: TextStyle(
                                      fontSize: isSmall ? 10 : 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EmergencySosScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(isSmall ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('🚨', style: TextStyle(fontSize: isSmall ? 18 : 20)),
                              ),
                            ),
                            SizedBox(width: isSmall ? 6 : 8),
                            Container(
                              padding: EdgeInsets.all(isSmall ? 6 : 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('🔔', style: TextStyle(fontSize: isSmall ? 18 : 20)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Society Name
                  Text(
                    'Shri Ramdev Park',
                    style: TextStyle(
                      fontSize: isSmall ? 22 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'CHS, Mira Road',
                        style: TextStyle(
                          fontSize: isSmall ? 13 : 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, size: 18, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick Actions Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                    children: [
                      _buildQuickActionTile(
                        emoji: '🧾',
                        title: 'View Bill',
                        subtitle: '₹4,850 due',
                        color: const Color(0xFFFFFAF0),
                        accentColor: Colors.orange,
                      ),
                      _buildQuickActionTile(
                        emoji: '✍️',
                        title: 'Complaint',
                        subtitle: '5 open',
                        color: const Color(0xFFFFE5E5),
                        accentColor: Colors.red,
                      ),
                      _buildQuickActionTile(
                        emoji: '🛵',
                        title: 'Visitor Gate',
                        subtitle: '3 pending',
                        color: const Color(0xFFF0F5FF),
                        accentColor: Colors.teal,
                      ),
                      _buildQuickActionTile(
                        emoji: '🔑',
                        title: 'Tenant Info',
                        subtitle: '124 units',
                        color: const Color(0xFFE5F5FF),
                        accentColor: Colors.blue,
                      ),
                      _buildQuickActionTile(
                        emoji: '🚗',
                        title: 'Parking',
                        subtitle: '98 spaces',
                        color: const Color(0xFFFFE5F5),
                        accentColor: Colors.purple,
                      ),
                      _buildQuickActionTile(
                        emoji: '📊',
                        title: 'Insights',
                        subtitle: 'Trends',
                        color: const Color(0xFFE5F5E5),
                        accentColor: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
              ),
            ),

            // Tabs
            Container(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: 8),
              child: Row(
                children: List.generate(
                  _tabs.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: Column(
                        children: [
                          Text(
                            _tabs[index],
                            style: TextStyle(
                              fontSize: isSmall ? 13 : 14,
                              fontWeight: _selectedTab == index ? FontWeight.bold : FontWeight.w500,
                              color: _selectedTab == index ? Colors.black : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedTab == index)
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.saffron,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          else
                            Container(
                              height: 2,
                              color: Colors.grey.shade300,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Tab Content
            if (_selectedTab == 0) ...[
              // Dashboard Tab - Society Features
              Padding(
                padding: EdgeInsets.all(isSmall ? 12 : 16),
                child: Column(
                  children: [
                    _buildFeatureCard(
                      emoji: '🚪',
                      title: 'Visitor Gate',
                      subtitle: 'Manage visitor entries',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      emoji: '🚗',
                      title: 'Parking Management',
                      subtitle: 'Request guest parking',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      emoji: '👥',
                      title: 'Tenant Management',
                      subtitle: 'Register tenants',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      emoji: '📄',
                      title: 'Bills & Maintenance',
                      subtitle: 'View maintenance bills',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      emoji: '📢',
                      title: 'Announcements',
                      subtitle: 'View society notices',
                    ),
                  ],
                ),
              ),
            ] else if (_selectedTab == 1) ...[
              // Photos Tab
              Container(
                padding: EdgeInsets.all(isSmall ? 12 : 16),
                color: Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmall ? 12 : 16),
                      decoration: BoxDecoration(
                        color: AppTheme.saffron,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmall ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: isSmall ? 20 : 24),
                          ),
                          SizedBox(width: isSmall ? 10 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Share a Photo',
                                  style: TextStyle(
                                    fontSize: isSmall ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Upload from gallery or take new • Max 10 MB',
                                  style: TextStyle(
                                    fontSize: isSmall ? 11 : 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recent Photos',
                      style: TextStyle(
                        fontSize: isSmall ? 13 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: isSmall ? 8 : 12,
                        mainAxisSpacing: isSmall ? 8 : 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        final categories = ['🎉 Events', '🔧 Maintenance', '🏊 Amenities', '🎊 Events', '🌳 Amenities', '🔧 Maintenance'];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                categories[index].split(' ')[0],
                                style: TextStyle(fontSize: isSmall ? 28 : 32),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                categories[index].split(' ')[1],
                                style: TextStyle(
                                  fontSize: isSmall ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else if (_selectedTab == 2) ...[
              // Notices Tab
              Padding(
                padding: EdgeInsets.all(isSmall ? 12 : 16),
                child: Column(
                  children: [
                    // Post Notice
                    Container(
                      padding: EdgeInsets.all(isSmall ? 12 : 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1B4E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmall ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.notifications, color: Colors.white, size: isSmall ? 20 : 24),
                          ),
                          SizedBox(width: isSmall ? 10 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Post a Notice',
                                  style: TextStyle(
                                    fontSize: isSmall ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Committee only • Attach image or PDF',
                                  style: TextStyle(
                                    fontSize: isSmall ? 11 : 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sample notices
                    ...[
                      {'title': 'URGENT NOTICE', 'category': '🔧 Maintenance', 'color': Colors.orange, 'time': 'Today'},
                      {'title': 'EVENT', 'category': '🎉 Events', 'color': Colors.teal, 'time': '2 days ago'},
                      {'title': 'AMENITY UPDATE', 'category': '🏊 Amenities', 'color': Colors.yellow.shade700, 'time': '5 days ago'},
                    ].map((notice) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: EdgeInsets.all(isSmall ? 12 : 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              left: BorderSide(color: notice['color'] as Color, width: 4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    notice['title'] as String,
                                    style: TextStyle(
                                      fontSize: isSmall ? 13 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    notice['time'] as String,
                                    style: TextStyle(
                                      fontSize: isSmall ? 11 : 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notice['category'] as String,
                                style: TextStyle(
                                  fontSize: isSmall ? 12 : 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _buildFeatureCard({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $title...'), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
