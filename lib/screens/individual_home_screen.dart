import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:convert';
import '../config/app_theme.dart';
import '../data/service_catalog.dart';
import 'add_complaint_screen.dart';
import 'all_categories_screen.dart';
import 'live_tracking_screen.dart';
import 'parking_management_screen.dart';
import 'search_list_screen.dart';
import 'service_category_screen.dart';
import 'society_screen.dart';
import 'sos_contacts_screen.dart';
import 'sos_emergency_screen.dart';
import 'tenant_management_screen.dart';

class IndividualHomeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  final String userRole;

  const IndividualHomeScreen({this.onNavigateToTab, this.userRole = 'individual', Key? key}) : super(key: key);

  @override
  State<IndividualHomeScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<IndividualHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late PageController _pageController;
  late Timer _bannerTimer;
  late ScrollController _scrollController;
  bool isDarkMode = false;
  int notificationCount = 3;
  int _currentBannerIndex = 0;
  final int _totalBanners = 3;
  final int _bannerSlideDelay = 4;
  bool _showButtons = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScrolling);
    _startAutoSlide();
  }

  void _handleScrolling() {
    final currentPosition = _scrollController.position.pixels;

    // Check if scrolling down or up by comparing with last position
    if (currentPosition > _lastScrollPosition) {
      // Scrolling down - hide buttons
      if (_showButtons) {
        setState(() => _showButtons = false);
      }
    } else if (currentPosition < _lastScrollPosition) {
      // Scrolling up - show buttons
      if (!_showButtons) {
        setState(() => _showButtons = true);
      }
    }

    _lastScrollPosition = currentPosition;
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
          // Silently catch
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    try {
      _pageController.dispose();
      _scrollController.dispose();
      _bannerTimer.cancel();
    } catch (e) {
      // Handle if late variables weren't initialized
    }
    super.dispose();
  }

  // Dark mode color getters
  Color get bgColor => isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFAF3ED);
  Color get cardColor => isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black;
  Color get textSecondaryColor => isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedOpacity(
        opacity: _showButtons ? 0.75 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: !_showButtons,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                // Message/Chat FAB - Bottom Right (15px from right edge)
                Positioned(
                  bottom: 16,
                  right: 15,
                  child: FloatingActionButton(
                    heroTag: 'message_fab',
                    onPressed: () {
                      _openWhatsApp();
                    },
                    backgroundColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.message, color: Colors.white, size: isSmall ? 22 : 26),
                  ),
                ),
                // Location FAB - Bottom Left (15px from left edge)
                Positioned(
                  bottom: 16,
                  left: 15,
                  child: FloatingActionButton(
                    heroTag: 'location_fab',
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
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
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
                left: isSmall ? 12 : 16,
                right: isSmall ? 12 : 16,
                bottom: isSmall ? 10 : 12,
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
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    readOnly: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchListScreen()),
                      );
                    },
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
                    height: isSmall ? 175 : 200,
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AllCategoriesScreen()),
                          );
                        },
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
                        iconPath: getCategoryIcon(service['name']),
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
                  // Emergency SOS Button - large, full-width, always the
                  // most prominent quick action here.
                  GestureDetector(
                    onTap: _openSOS,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: isSmall ? 18 : 22, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE63946),
                        borderRadius: BorderRadius.circular(isSmall ? 16 : 18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE63946).withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🆘', style: TextStyle(fontSize: isSmall ? 24 : 28)),
                          SizedBox(width: isSmall ? 10 : 12),
                          Text(
                            'SOS Emergency',
                            style: TextStyle(
                              fontSize: isSmall ? 18 : 21,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmall ? 10 : 12),
                  // Access Society Dashboard Button
                  GestureDetector(
                    onTap: () {
                      _navigateToSocietyDashboard();
                    },
                    child: Container(
                      width: double.infinity,
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
                        onTap: () => _runIfSocietyMember(_showViewBillSheet),
                      ),
                      _buildActionCard(
                        emoji: '✍️',
                        title: 'Complaint',
                        badge: null,
                        onTap: () => _runIfSocietyMember(() => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddComplaintScreen()),
                            )),
                      ),
                      _buildActionCard(
                        emoji: '🛵',
                        title: 'Visitor Gate',
                        badge: '1',
                        onTap: () => _runIfSocietyMember(_showVisitorGateRequest),
                      ),
                      _buildActionCard(
                        emoji: '🔑',
                        title: 'Tenant Info',
                        badge: null,
                        onTap: () => _runIfSocietyMember(() => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TenantManagementScreen()),
                            )),
                      ),
                      _buildActionCard(
                        emoji: '🚗',
                        title: 'Parking',
                        badge: null,
                        onTap: () => _runIfSocietyMember(() => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ParkingManagementScreen()),
                            )),
                      ),
                      _buildActionCard(
                        emoji: '📊',
                        title: 'Full Dashboard',
                        badge: null,
                        onTap: _navigateToSocietyDashboard,
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
    String? iconPath,
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
        final categoryServices = getServicesForCategory(name, emoji);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceCategoryScreen(
              categoryName: name,
              categoryEmoji: emoji,
              categoryIconPath: iconPath,
              description: getCategoryDescription(name),
              services: categoryServices,
            ),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
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
        padding: iconPath != null ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: isSmall ? 10 : 12, vertical: isSmall ? 12 : 16),
        child: iconPath != null
            ? _buildPhotoServiceCard(iconPath: iconPath, name: name, time: time, isSmall: isSmall)
            : Column(
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

  /// Category tile that's a real photo, filling the whole card, with the
  /// category name (and time badge) overlaid on a dark scrim at the bottom
  /// so the text stays readable against any photo.
  Widget _buildPhotoServiceCard({
    required String iconPath,
    required String name,
    required String time,
    required bool isSmall,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(iconPath, fit: BoxFit.cover),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(isSmall ? 8 : 10, isSmall ? 20 : 24, isSmall ? 8 : 10, isSmall ? 8 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: 0.2,
                    shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (time.isNotEmpty) ...[
                  SizedBox(height: isSmall ? 4 : 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.neonGreen, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('⚡', style: TextStyle(fontSize: isSmall ? 8 : 10)),
                        SizedBox(width: isSmall ? 2 : 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: isSmall ? 8 : 10,
                            color: Colors.white,
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
        ),
      ],
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


  Widget _buildActionCard({
    required String emoji,
    required String title,
    String? badge,
    VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return GestureDetector(
      onTap: onTap ??
          () {
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

  /// The 6 Society Actions cards only do their real thing for society
  /// members. 'society' role accounts are always members. 'individual'
  /// accounts must register + get admin-approved first (same gate as the
  /// Society tab) - not-yet-registered taps open that registration screen,
  /// already-pending taps just remind them to wait.
  Future<void> _runIfSocietyMember(VoidCallback action) async {
    if (widget.userRole == 'society') {
      action();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('society_registration_status');
    if (!mounted) return;

    if (status == 'pending') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Text('⏳', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Expanded(child: Text('Approval Pending')),
            ],
          ),
          content: const Text(
            'Please wait until the admin approves you as a society member. '
            'You will be provided a Society Member Account ID once approved.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.saffron),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SocietyScreen()),
    );
  }

  /// Shows outstanding maintenance bills (uploaded by the society admin)
  /// with a Pay Now button. NOTE: this opens Razorpay's site as a
  /// placeholder redirect - a real checkout for the exact bill amount
  /// needs a Razorpay merchant account wired up to a backend, which
  /// doesn't exist yet.
  Future<void> _showViewBillSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final bills = (prefs.getStringList('bills') ?? [])
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    final pending = bills.where((b) => b['status'] == 'Pending').toList();
    double total = 0;
    for (final b in pending) {
      total += double.tryParse(b['amount'].toString()) ?? 0;
    }

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🧾 Maintenance Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Uploaded and updated by your society admin',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              if (pending.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No pending bills 🎉', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                )
              else ...[
                ...pending.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              b['description'] ?? '',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('₹${b['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    )),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Outstanding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.saffron, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _payViaRazorpay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.saffron,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _payViaRazorpay() async {
    final uri = Uri.parse('https://razorpay.com/payment-link/');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Razorpay')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Razorpay: $e')),
        );
      }
    }
  }

  /// The one cross-account link in this app: a security guard captures a
  /// visitor and it shows up here for the resident to approve/deny. Until
  /// a real guard-submitted request exists (same local storage, so this
  /// only works if guard + resident are testing on the same device/browser
  /// for now), shows a demo request so the interaction is visible.
  Future<void> _showVisitorGateRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final visitors = prefs.getStringList('visitors') ?? [];

    Map<String, dynamic>? pendingEntry;
    int pendingIndex = -1;
    for (int i = visitors.length - 1; i >= 0; i--) {
      final v = jsonDecode(visitors[i]) as Map<String, dynamic>;
      if (v['guardName'] != null && (v['status'] == null || v['status'] == 'pending')) {
        pendingEntry = v;
        pendingIndex = i;
        break;
      }
    }

    final isDemo = pendingEntry == null;
    final entry = pendingEntry ??
        {
          'name': 'Swiggy Delivery Partner',
          'purpose': 'Food Delivery',
          'flatNo': 'Your Flat',
          'photoBase64': null,
        };

    if (!mounted) return;
    final decision = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚪 Visitor at Gate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: entry['photoBase64'] != null
                  ? Image.memory(base64Decode(entry['photoBase64']), width: 100, height: 100, fit: BoxFit.cover)
                  : Container(
                      width: 100,
                      height: 100,
                      color: Colors.orange.shade50,
                      child: const Center(child: Text('🛵', style: TextStyle(fontSize: 48))),
                    ),
            ),
            const SizedBox(height: 12),
            Text(entry['name'] ?? 'Visitor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${entry['purpose'] ?? ''} • Flat ${entry['flatNo'] ?? ''}', style: TextStyle(color: Colors.grey.shade600)),
            if (isDemo) ...[
              const SizedBox(height: 10),
              Text(
                'Demo request - no real guest at the gate yet',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'deny'),
            child: const Text('Deny Entry', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'approve'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve Entry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (decision == null) return;

    if (!isDemo && pendingIndex != -1) {
      final v = jsonDecode(visitors[pendingIndex]) as Map<String, dynamic>;
      v['status'] = decision == 'approve' ? 'Approved' : 'Denied';
      visitors[pendingIndex] = jsonEncode(v);
      await prefs.setStringList('visitors', visitors);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(decision == 'approve' ? '✅ Entry approved - guard notified' : '❌ Entry denied'),
          backgroundColor: decision == 'approve' ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _openSOS() async {
    final prefs = await SharedPreferences.getInstance();
    final hasContacts = (prefs.getString('sos_contacts') ?? '').isNotEmpty;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => hasContacts ? const SOSEmergencyScreen() : const SOSContactsScreen(),
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
    if (widget.onNavigateToTab != null) {
      // Switch to the Society tab in the bottom nav, which already
      // shows the correct screen for the user's role.
      widget.onNavigateToTab!(3);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SocietyScreen(),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
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
