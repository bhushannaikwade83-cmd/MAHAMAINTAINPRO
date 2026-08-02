import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> services = [
    {'emoji': '⚡', 'name': 'Insta Help', 'hindi': '', 'time': '46 min', 'color': Color(0xFFFFE5E5)},
    {'emoji': '💇‍♀️', 'name': 'Women\'s Salon', 'hindi': 'सौंदर्य', 'time': '', 'color': Color(0xFFFFF0E5)},
    {'emoji': '💆‍♂️', 'name': 'Men\'s Salon', 'hindi': 'Massage', 'time': '', 'color': Color(0xFFF0F5FF)},
    {'emoji': '🧹', 'name': 'Cleaning', 'hindi': 'स्वच्छता', 'time': '', 'color': Color(0xFFE5F5E5)},
    {'emoji': '🎨', 'name': 'Painting', 'hindi': 'New', 'time': '', 'color': Color(0xFFFFF5E5)},
    {'emoji': '❄️', 'name': 'AC & Appliance', 'hindi': '', 'time': '46 min', 'color': Color(0xFFE5F5FF)},
    {'emoji': '🔧', 'name': 'Electric / Plumb', 'hindi': '', 'time': '46 min', 'color': Color(0xFFFFF5E5)},
    {'emoji': '🚗', 'name': 'Vehicle Care', 'hindi': 'Car & Bike', 'time': '', 'color': Color(0xFFFFE5F5)},
    {'emoji': '🍳', 'name': 'Food & Catering', 'hindi': 'Home Cook', 'time': '', 'color': Color(0xFFF5E5FF)},
    {'emoji': '🏥', 'name': 'Hospital', 'hindi': '', 'time': '', 'color': Color(0xFFE5FFE5)},
    {'emoji': '🙏', 'name': 'Prayer/Pooja', 'hindi': '', 'time': '', 'color': Color(0xFFFFFFE5)},
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
            // Header with Society Info
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with location and notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: AppTheme.saffron, size: 20),
                          const SizedBox(width: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR SOCIETY',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.saffron,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'तुमची सोसायटी',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.saffron,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.notifications_none, color: Colors.grey, size: 20),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: AssetImage('images/logo.jpeg'),
                            onBackgroundImageError: (exception, stackTrace) {},
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.saffron.withOpacity(0.2),
                              ),
                              child: Center(
                                child: Text('👤', style: TextStyle(fontSize: 16)),
                              ),
                            ),
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
                      fontSize: isSmall ? 22 : 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'CHS, Mira Road',
                        style: TextStyle(
                          fontSize: isSmall ? 13 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, size: 18, color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for services, society, help...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.saffron,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.search, color: Colors.white, size: 20),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active Booking Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.saffron, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: Color(0xFFFFF8F5),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Booking • Today',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.saffron,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bathroom Deep Clean',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Suresh arriving in 14 min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text('🧹', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Icon(Icons.arrow_forward, color: AppTheme.saffron, size: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Services Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'What do you need today?',
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
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _buildServiceCard(
                        emoji: service['emoji'],
                        name: service['name'],
                        hindi: service['hindi'],
                        time: service['time'],
                        bgColor: service['color'],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Chat Support Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '💬',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chat with Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking $name...')),
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
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
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
                    fontSize: 11,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
