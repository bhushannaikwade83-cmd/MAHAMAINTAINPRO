import 'package:flutter/material.dart';
import 'dart:async';
import '../config/app_theme.dart';
import 'live_tracking_screen.dart';
import 'service_category_screen.dart';
import 'society_tab_screen.dart';

class IndividualHomeScreen extends StatefulWidget {
  const IndividualHomeScreen({Key? key}) : super(key: key);

  @override
  State<IndividualHomeScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<IndividualHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late PageController _pageController;
  late Timer _bannerTimer;
  bool isDarkMode = false;
  int notificationCount = 3;
  int _currentBannerIndex = 0;
  final int _totalBanners = 3;
  final int _bannerSlideDelay = 4; // seconds

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _bannerTimer = Timer.periodic(Duration(seconds: _bannerSlideDelay), (timer) {
      if (mounted && _pageController.hasClients) {
        try {
          final nextPage = (_currentBannerIndex + 1) % _totalBanners;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          // Silently catch exceptions from disposed widgets
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _bannerTimer.cancel();
    super.dispose();
  }

  // Dark mode color getters
  Color get bgColor => isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFAF3ED);
  Color get cardColor => isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black;
  Color get textSecondaryColor => isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

  final List<Map<String, dynamic>> personalServices = [
    {'emoji': '⚡', 'name': 'Insta Help', 'hindi': '', 'time': '46 min', 'color': Color(0xFFFFE5E5)},
    {'emoji': '💇‍♀️', 'name': 'Women\'s Salon', 'hindi': 'सौंदर्य', 'time': '', 'color': Color(0xFFFFF0E5)},
    {'emoji': '💆‍♂️', 'name': 'Men\'s Salon', 'hindi': 'Massage', 'time': '', 'color': Color(0xFFF0F5FF)},
    {'emoji': '🧹', 'name': 'Cleaning', 'hindi': 'स्वच्छता', 'time': '', 'color': Color(0xFFE5F5E5)},
    {'emoji': '🎨', 'name': 'Painting', 'hindi': 'New', 'time': '', 'color': Color(0xFFFFF5E5)},
    {'emoji': '❄️', 'name': 'AC & Appliance', 'hindi': '', 'time': '46 min', 'color': Color(0xFFE5F5FF)},
    {'emoji': '🔧', 'name': 'Electric / Plumb', 'hindi': '', 'time': '46 min', 'color': Color(0xFFFFF5E5)},
    {'emoji': '🚗', 'name': 'Vehicle Care', 'hindi': 'Car & Bike', 'time': '', 'color': Color(0xFFFFE5F5)},
    {'emoji': '🍳', 'name': 'Food & Catering', 'hindi': 'Home Cook', 'time': '', 'color': Color(0xFFF5E5FF)},
    {'emoji': '🏥', 'name': 'Health & Care', 'hindi': 'Nurse / Physio', 'time': '', 'color': Color(0xFFE5FFE5)},
    {'emoji': '🙏', 'name': 'Pooja Services', 'hindi': 'पूजा सेवा', 'time': '', 'color': Color(0xFFFFFFE5)},
    {'emoji': '🎉', 'name': 'Festival Services', 'hindi': 'New', 'time': '', 'color': Color(0xFFFFE5E5)},
    {'emoji': '🐜', 'name': 'Pest Control', 'hindi': 'कीट नियंत्रण', 'time': '', 'color': Color(0xFFFFF5E5)},
    {'emoji': '🏢', 'name': 'Society Hub', 'hindi': 'समाज', 'time': '', 'color': Color(0xFFE5F5FF)},
    {'emoji': '🏠', 'name': 'Real Estate', 'hindi': 'New', 'time': '', 'color': Color(0xFFFFE5F5)},
    {'emoji': '🔮', 'name': 'Hologram', 'hindi': 'New', 'time': '', 'color': Color(0xFFF5E5FF)},
    {'emoji': '✈️', 'name': 'Tours & Travels', 'hindi': 'Hire Driver', 'time': '', 'color': Color(0xFFE5FFE5)},
  ];

  final List<Map<String, dynamic>> societyServices = [
    {'emoji': '📄', 'name': 'View Bill', 'color': Color(0xFFFFE5E5)},
    {'emoji': '✏️', 'name': 'Complaint', 'color': Color(0xFFFFF0E5)},
    {'emoji': '🛵', 'name': 'Visitor Gate', 'color': Color(0xFFF0F5FF), 'badge': '1'},
    {'emoji': '🔑', 'name': 'Tenant Info', 'color': Color(0xFFE5F5E5)},
    {'emoji': '🚗', 'name': 'Parking', 'color': Color(0xFFFFF5E5)},
    {'emoji': '📊', 'name': 'Full Dashboard', 'color': Color(0xFFE5F5FF)},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: Stack(
        children: [
          // WhatsApp FAB - Bottom Right
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                _openWhatsApp();
              },
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Text(
                'W',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 28 : 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Tracking FAB - Bottom Left
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LiveTrackingScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.saffron,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.location_on, color: Colors.white, size: isSmall ? 22 : 26),
            ),
          ),
        ],
      ),
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
                top: MediaQuery.of(context).padding.top + (isSmall ? 10 : 12),
                left: isSmall ? 12 : 16,
                right: isSmall ? 12 : 16,
                bottom: isSmall ? 12 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: isSmall ? 6 : 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: isSmall ? 30 : 36,
                                height: isSmall ? 30 : 36,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: isSmall ? 6 : 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WELCOME',
                                  style: TextStyle(
                                    fontSize: isSmall ? 7 : 8,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  'Home Services',
                                  style: TextStyle(
                                    fontSize: isSmall ? 11 : 12,
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
                          // Notification Button
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('You have $notificationCount new notifications'),
                                  backgroundColor: AppTheme.saffron,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isSmall ? 8 : 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text('🔔', style: TextStyle(fontSize: isSmall ? 16 : 18)),
                                ),
                                if (notificationCount > 0)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$notificationCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: isSmall ? 6 : 10),
                          // Theme Toggle Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isDarkMode = !isDarkMode;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isDarkMode ? 'Dark Mode Enabled' : 'Light Mode Enabled'),
                                  backgroundColor: AppTheme.saffron,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(isSmall ? 8 : 10),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                isDarkMode ? '☀️' : '🌙',
                                style: TextStyle(fontSize: isSmall ? 16 : 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Society Name & Greeting
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shri Ramdev Park 🏠',
                        style: TextStyle(
                          fontSize: isSmall ? 22 : 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(width: 4),
                            Text(
                              'CHS, Mira Road',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Change',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(Icons.expand_more, size: 12, color: Colors.white.withOpacity(0.9)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '🔍 Search services...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.mic, color: AppTheme.saffron, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hero Banner Carousel
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
              child: Column(
                children: [
                  SizedBox(
                    height: isSmall ? 140 : 160,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentBannerIndex = index);
                      },
                      children: [
                        _buildHeroBanner(
                          title: '50% Off Cleaning Services',
                          subtitle: 'Limited time offer',
                          bgColor: const Color(0xFFE8F4F8),
                          textColor: const Color(0xFF2C5F7F),
                        ),
                        _buildHeroBanner(
                          title: 'Book Expert Plumber',
                          subtitle: '24/7 Emergency Service',
                          bgColor: const Color(0xFFF0E8F8),
                          textColor: const Color(0xFF5F2C7F),
                        ),
                        _buildHeroBanner(
                          title: 'Free AC Maintenance Check',
                          subtitle: 'This month only',
                          bgColor: const Color(0xFFF8E8E8),
                          textColor: const Color(0xFF7F2C2C),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmall ? 8 : 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        width: _currentBannerIndex == index ? 28 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentBannerIndex == index
                              ? AppTheme.saffron
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Personal Services
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What do you need to...',
                              style: TextStyle(
                                fontSize: isSmall ? 17 : 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: isSmall ? 3 : 4),
                            Container(
                              width: isSmall ? 30 : 40,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppTheme.saffron,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'See all →',
                          style: TextStyle(
                            fontSize: isSmall ? 11 : 12,
                            color: AppTheme.saffron,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 12 : 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: isSmall ? 8 : 12,
                      mainAxisSpacing: isSmall ? 12 : 14,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: personalServices.length,
                    itemBuilder: (context, index) {
                      final service = personalServices[index];
                      return _buildServiceCard(
                        emoji: service['emoji'],
                        name: service['name'],
                        hindi: service['hindi'],
                        time: service['time'],
                        bgColor: service['color'],
                      );
                    },
                  ),
                  SizedBox(height: isSmall ? 18 : 24),
                ],
              ),
            ),

            // For Your Society - All Quick Actions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: isSmall ? 10 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Society Actions',
                        style: TextStyle(
                          fontSize: isSmall ? 18 : 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening Full Dashboard...')),
                          );
                        },
                        child: Text(
                          'Dashboard →',
                          style: TextStyle(
                            fontSize: isSmall ? 12 : 13,
                            color: AppTheme.saffron,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 10 : 14),
                  Container(
                    width: isSmall ? 30 : 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppTheme.saffron,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  SizedBox(height: isSmall ? 14 : 18),
                  // Quick Action Buttons
                  Row(
                    children: [
                      // SOS Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _showSecretaryContactDialog();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE63946),
                              borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE63946).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '🆘 SOS',
                                  style: TextStyle(
                                    fontSize: isSmall ? 12 : 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 10 : 12),
                      // Access Society Dashboard Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _navigateToSocietyDashboard();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.saffron,
                              borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.saffron.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '🏛️ Access Society Dashboard',
                                  style: TextStyle(
                                    fontSize: isSmall ? 11 : 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 16 : 20),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: isSmall ? 12 : 14,
                    mainAxisSpacing: isSmall ? 12 : 14,
                    childAspectRatio: 0.95,
                    children: [
                      _buildActionCard(
                        emoji: '🧾',
                        title: 'View Bill',
                        badge: null,
                      ),
                      _buildActionCard(
                        emoji: '✍️',
                        title: 'Complaint',
                        badge: null,
                      ),
                      _buildActionCard(
                        emoji: '🛵',
                        title: 'Visitor Gate',
                        badge: '1',
                      ),
                      _buildActionCard(
                        emoji: '🔑',
                        title: 'Tenant Info',
                        badge: null,
                      ),
                      _buildActionCard(
                        emoji: '🚗',
                        title: 'Parking',
                        badge: null,
                      ),
                      _buildActionCard(
                        emoji: '📊',
                        title: 'Full Dashboard',
                        badge: null,
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 18 : 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String emoji,
    required String name,
    required String hindi,
    required String time,
    required Color bgColor,
    Color? textColorOverride,
    Color? secondaryColorOverride,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;
    final displayTextColor = textColorOverride ?? (isDarkMode ? Colors.white : Colors.black87);
    final displaySecondaryColor = secondaryColorOverride ?? textSecondaryColor;
    return GestureDetector(
      onTap: () {
        final categoryServices = _getServicesForCategory(name, emoji);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceCategoryScreen(
              categoryName: name,
              categoryEmoji: emoji,
              description: _getCategoryDescription(name),
              services: categoryServices,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? cardColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 12, vertical: isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isSmall ? 48 : 56,
              height: isSmall ? 48 : 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: isSmall ? 28 : 30),
                ),
              ),
            ),
            SizedBox(height: isSmall ? 8 : 12),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmall ? 11 : 13,
                  fontWeight: FontWeight.bold,
                  color: displayTextColor,
                  height: 1.2,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hindi.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: isSmall ? 4 : 6),
                child: Text(
                  hindi,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 9 : 10,
                    color: AppTheme.saffron,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                ),
              ),
            if (time.isNotEmpty) ...[
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neonGreen.withOpacity(0.2),
                      AppTheme.neonGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.neonGreen.withOpacity(isDarkMode ? 0.5 : 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '⚡',
                      style: TextStyle(fontSize: isSmall ? 8 : 10),
                    ),
                    SizedBox(width: isSmall ? 2 : 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: isSmall ? 8 : 10,
                        color: AppTheme.neonGreen,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openWhatsAppComplaint() {
    final message = Uri.encodeComponent('Hi, I have a complaint regarding our society.');
    final whatsappUrl = 'https://wa.me/919876543210?text=$message';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening WhatsApp...'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
    // In a real app, you would use: launchUrl(Uri.parse(whatsappUrl))
    // For now, just show the message
  }

  Widget _buildSocietyCard({
    required String emoji,
    required String name,
    required Color bgColor,
    String? badge,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;
    return GestureDetector(
      onTap: () {
        if (name == 'Complaint') {
          _openWhatsAppComplaint();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening $name...')),
          );
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgColor, bgColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: bgColor.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(isSmall ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: isSmall ? 42 : 56),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 12, vertical: isSmall ? 10 : 12),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmall ? 11 : 13,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.neonGreen, Color(0xFF00FF00)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getCategoryDescription(String categoryName) {
    final descriptions = {
      "Insta Help": "Instant help for common problems",
      "Women's Salon": "At-home beauty & wellness services",
      "Men's Salon": "Haircut, massage & grooming services",
      "Cleaning": "Deep clean, kitchen, bathroom & more",
      "Painting": "Interior, exterior, waterproofing & texture",
      "AC & Appliance": "AC, fridge, washing machine, TV & more",
      "Electric / Plumb": "46-min response • All home repairs",
      "Vehicle Care": "Car & bike wash, detailing, AC & repairs",
      "Food & Catering": "Home cook, tiffin, party catering & more",
      "Health & Care": "Nurse, physio, blood test & elder care",
      "Pooja Services": "Pandit, pooja samagri & full setup",
      "Festival Services": "Ganpati, Diwali, Navratri & all festivals",
      "Pest Control": "Safe, effective & certified treatments",
      "Society Hub": "Gate, lift, CCTV, AMC & management",
      "Real Estate": "Buy, sell, rent & property services",
      "Hologram": "3D hologram display, events & branding",
      "Tours & Travels": "Car rentals, tour packages & professional drivers",
    };
    return descriptions[categoryName] ?? "Professional services";
  }

  List<Map<String, dynamic>> _getServicesForCategory(String categoryName, String emoji) {
    final servicesMap = {
      "Insta Help": [
        {'name': 'Electrical Fault', 'emoji': '⚡', 'duration': '30-45 min', 'rating': 4.8, 'price': 149},
        {'name': 'Leaking Tap / Pipe', 'emoji': '💧', 'duration': '30-45 min', 'rating': 4.7, 'price': 179},
        {'name': 'Door Lock Issue', 'emoji': '🔑', 'duration': '30-45 min', 'rating': 4.8, 'price': 199},
      ],
      "Women's Salon": [
        {'name': 'Hair Cut & Styling (Women)', 'emoji': '✂️', 'duration': '45-60 min', 'rating': 4.9, 'price': 399},
        {'name': 'Facial (Basic / D-Tan)', 'emoji': '🧴', 'duration': '60 min', 'rating': 4.8, 'price': 499},
        {'name': 'Full Body Waxing', 'emoji': '✨', 'duration': '90 min', 'rating': 4.7, 'price': 799},
      ],
      "Men's Salon": [
        {'name': 'Hair Cut & Styling (Men)', 'emoji': '✂️', 'duration': '30-45 min', 'rating': 4.9, 'price': 249},
        {'name': 'Head Massage', 'emoji': '💆‍♂️', 'duration': '30 min', 'rating': 4.9, 'price': 299},
        {'name': 'Beard Grooming', 'emoji': '🧔', 'duration': '30 min', 'rating': 4.8, 'price': 199},
      ],
      "Cleaning": [
        {'name': 'Home Deep Clean (1BHK)', 'emoji': '🧹', 'duration': '3-4 hrs', 'rating': 4.9, 'price': 999},
        {'name': 'Home Deep Clean (2BHK)', 'emoji': '🧹', 'duration': '4-5 hrs', 'rating': 4.9, 'price': 1499},
      ],
      "Painting": [
        {'name': 'Wall Painting (Per sq.ft)', 'emoji': '🎨', 'rating': 4.6, 'price': 35},
        {'name': 'Full Home Painting (1BHK)', 'emoji': '🏠', 'duration': '2-3 days', 'rating': 4.8, 'price': 8999},
      ],
      "AC & Appliance": [
        {'name': 'AC Service & Deep Clean', 'emoji': '❄️', 'duration': '1.5-2 hrs', 'rating': 4.8, 'price': 499},
        {'name': 'AC Gas Refill (R32 / R410)', 'emoji': '❄️', 'duration': '1-1.5 hrs', 'rating': 4.7, 'price': 1299},
      ],
      "Electric / Plumb": [
        {'name': 'Electrician (General Visit)', 'emoji': '⚡', 'duration': '45 min', 'rating': 4.8, 'price': 199},
        {'name': 'Fan Installation / Repair', 'emoji': '💨', 'duration': '30-45 min', 'rating': 4.8, 'price': 249},
      ],
      "Vehicle Care": [
        {'name': 'Car Wash (Basic Exterior)', 'emoji': '🚗', 'duration': '45 min', 'rating': 4.7, 'price': 299},
        {'name': 'Car Interior Deep Clean', 'emoji': '🚗', 'duration': '2-3 hrs', 'rating': 4.8, 'price': 799},
      ],
      "Food & Catering": [
        {'name': 'Home Cook (Per Visit)', 'emoji': '👨‍🍳', 'duration': '2-3 hrs', 'rating': 4.8, 'price': 499},
        {'name': 'Tiffin Service (Monthly)', 'emoji': '📦', 'duration': 'Monthly', 'rating': 4.7, 'price': 3499},
      ],
      "Health & Care": [
        {'name': 'Nurse / Attendant (Day Shift)', 'emoji': '👩‍⚕️', 'duration': '8 hrs', 'rating': 4.9, 'price': 1499},
        {'name': 'Nurse / Attendant (Night Shift)', 'emoji': '👩‍⚕️', 'duration': '10 hrs', 'rating': 4.9, 'price': 1799},
      ],
      "Pooja Services": [
        {'name': 'Ganesh Pooja Setup & Pandit', 'emoji': '🐘', 'duration': '2-3 hrs', 'rating': 4.9, 'price': 2499},
        {'name': 'Griha Pravesh Pooja', 'emoji': '🏠', 'duration': '3-4 hrs', 'rating': 4.9, 'price': 3499},
      ],
      "Festival Services": [
        {'name': 'Ganpati Decoration & Setup', 'emoji': '🪔', 'rating': 4.9, 'price': 3999},
        {'name': 'Ganpati Visarjan Arrangements', 'emoji': '🐘', 'duration': '2-3 hrs', 'rating': 4.8, 'price': 1999},
      ],
      "Pest Control": [
        {'name': 'General Pest Control (1BHK)', 'emoji': '🐜', 'duration': '1-2 hrs', 'rating': 4.7, 'price': 799},
        {'name': 'General Pest Control (2BHK)', 'emoji': '🐜', 'duration': '1.5-2 hrs', 'rating': 4.7, 'price': 999},
      ],
      "Society Hub": [
        {'name': 'Society Gate Motor Repair', 'emoji': '🚪', 'duration': '2-3 hrs', 'rating': 4.8, 'price': 1299},
        {'name': 'Lift Maintenance / Repair', 'emoji': '🛗', 'rating': 4.9, 'price': 2499},
      ],
      "Real Estate": [
        {'name': 'Property Site Visit & Inspection', 'emoji': '🏠', 'duration': '2-3 hrs', 'rating': 4.8, 'price': 499},
        {'name': 'Flat / Home for Rent (Listing)', 'emoji': '🔑', 'duration': '7-14 days', 'rating': 4.7, 'price': 999},
      ],
      "Hologram": [
        {'name': '3D Hologram Fan Display (Rental)', 'emoji': '🔮', 'rating': 4.9, 'price': 2999},
        {'name': 'Hologram Fan Purchase & Setup', 'emoji': '✨', 'duration': '1-2 days', 'rating': 4.9, 'price': 14999},
      ],
      "Tours & Travels": [
        {'name': 'Hire Driver (Local - 4 hrs)', 'emoji': '👨‍✈️', 'duration': '4 hrs', 'rating': 4.8, 'price': 499},
        {'name': 'Hire Driver (Local - 8 hrs)', 'emoji': '👨‍✈️', 'duration': '8 hrs', 'rating': 4.9, 'price': 899},
      ],
    };
    return servicesMap[categoryName] ?? [];
  }

  Widget _buildActionCard({
    required String emoji,
    required String title,
    String? badge,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $title...'), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmall ? 24 : 28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: isSmall ? 44 : 52,
                      height: isSmall ? 44 : 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E6),
                        borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: isSmall ? 26 : 30),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 11 : 13,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: isSmall ? 22 : 26,
                  height: isSmall ? 22 : 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE63946),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openWhatsApp() {
    final message = Uri.encodeComponent('Hi! I need help with a service.');
    final whatsappUrl = 'https://wa.me/919876543210?text=$message';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening WhatsApp...'),
        backgroundColor: Color(0xFF25D366),
        duration: Duration(seconds: 1),
      ),
    );
    // In production: launchUrl(Uri.parse(whatsappUrl))
  }

  void _navigateToSocietyDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SocietyTabScreen(),
      ),
    );
  }

  void _showSecretaryContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Text('🆘 ', style: TextStyle(fontSize: 20)),
            const Text('Secretary Contact', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE63946).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Shri Ramdev Park Secretary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, color: AppTheme.saffron, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '+91 98765 43210',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE63946),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, color: AppTheme.saffron, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'secretary@ramdevpark.in',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final message = Uri.encodeComponent('Emergency: Need immediate assistance');
              final whatsappUrl = 'https://wa.me/919876543210?text=$message';
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening WhatsApp...')),
              );
            },
            child: const Text('📱 WhatsApp', style: TextStyle(color: Color(0xFF25D366))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner({
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $title...')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: textColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
