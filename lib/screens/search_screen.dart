import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'live_tracking_screen.dart';
import 'service_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Orange Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.saffron, AppTheme.saffronDark],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Text('👤', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR SERVICES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Personal Services',
                                  style: TextStyle(
                                    fontSize: 12,
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('🔔', style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('🌙', style: TextStyle(fontSize: 20)),
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
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search services, society',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Booking Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LiveTrackingScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.saffron, width: 2.5),
                    borderRadius: BorderRadius.circular(16),
                    color: Color(0xFFFFF8F5),
                  ),
                  child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Booking',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.saffron,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '• Today',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.saffron,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bathroom',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Deep Clean',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Suresh arriving',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'in 14 min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFE5E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('🧹', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.saffron,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Personal Services
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'What do you need to...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'See all →',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.saffron,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
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
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // For Your Society
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For Your Society',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: societyServices.length,
                    itemBuilder: (context, index) {
                      final service = societyServices[index];
                      return _buildSocietyCard(
                        emoji: service['emoji'],
                        name: service['name'],
                        bgColor: service['color'],
                        badge: service['badge'],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
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
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(
              serviceName: name,
              serviceEmoji: emoji,
              description: 'At-home beauty & wellness services',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (hindi.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  hindi,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.saffron,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                ),
              ),
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.saffron,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '⚡',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocietyCard({
    required String emoji,
    required String name,
    required Color bgColor,
    String? badge,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $name...')),
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 52),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
