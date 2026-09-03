import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';
import '../data/service_catalog.dart';
import '../utils/constants.dart';
import 'service_category_screen.dart';

/// Full list of service categories, reached via "See all" on the home screen.
class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  late List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/get-services.php');
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['categories'] != null) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(data['categories']);
            _isLoading = false;
          });
          debugPrint('✅ Categories loaded: ${_categories.length} found');

          // Debug each category's image
          for (var category in _categories) {
            final name = category['name'] ?? 'Unknown';
            final imagePath = category['image_path'];
            debugPrint('📸 $name → image_path: $imagePath');
            if (imagePath == null || imagePath.isEmpty) {
              debugPrint('   ⚠️ Missing image for $name');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('All Categories'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.saffron),
            )
          : GridView.builder(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: isSmall ? 8 : 12,
          mainAxisSpacing: isSmall ? 12 : 14,
          childAspectRatio: 0.95,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final emoji = category['emoji'] as String? ?? '🔧';
          final name = category['name'] as String? ?? 'Service';
          final colorHex = category['color'] as String? ?? '#FFFFFF';
          final bgColor = _hexToColor(colorHex);
          final imagePath = category['image_path'];

          return GestureDetector(
            onTap: () {
              final services = (category['services'] as List<dynamic>?)
                  ?.map((s) => Map<String, dynamic>.from(s as Map))
                  .toList() ?? [];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceCategoryScreen(
                    categoryName: name,
                    categoryEmoji: emoji,
                    categoryImagePath: imagePath,
                    description: getCategoryDescription(name),
                    services: services,
                  ),
                ),
              );
            },
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: imagePath != null ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: isSmall ? 10 : 12, vertical: isSmall ? 12 : 16),
              child: imagePath != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          '${'https://digitrixmedia.com/mahamaintainpro/assets/services'}/$imagePath',
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
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
                            child: Text(
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
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isSmall ? 48 : 56,
                          height: isSmall ? 48 : 56,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(emoji, style: TextStyle(fontSize: isSmall ? 28 : 30)),
                          ),
                        ),
                        SizedBox(height: isSmall ? 4 : 6),
                        Flexible(
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmall ? 10 : 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.1,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('FF$hexColor', radix: 16));
    } else if (hexColor.length == 8) {
      return Color(int.parse(hexColor, radix: 16));
    }
    return const Color(0xFFFFFFFF);
  }
}
