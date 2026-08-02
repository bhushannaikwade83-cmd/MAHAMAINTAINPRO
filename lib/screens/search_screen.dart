import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'live_tracking_screen.dart';
import 'service_category_screen.dart';

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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF8F5), Color(0xFFFFEAE0)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.saffron, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.saffron.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active Booking',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Today • In Progress',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '14 min',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Service Info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFE5E5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('🧹', style: const TextStyle(fontSize: 28)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bathroom Deep Clean',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Suresh arriving in 14 min',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.saffron,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.saffron.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                          ),
                        ],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What do you need to...',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppTheme.saffron,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'See all →',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.saffron,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
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
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 44),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (hindi.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  hindi,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.saffron,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
              ),
            if (time.isNotEmpty) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.saffron.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '⚡',
                      style: const TextStyle(fontSize: 9),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.saffron,
                        fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
