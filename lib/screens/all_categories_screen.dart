import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../data/service_catalog.dart';
import 'service_category_screen.dart';

/// Full list of service categories, reached via "See all" on the home screen.
class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({Key? key}) : super(key: key);

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
      body: GridView.builder(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: isSmall ? 8 : 12,
          mainAxisSpacing: isSmall ? 12 : 14,
          childAspectRatio: 0.95,
        ),
        itemCount: personalServices.length,
        itemBuilder: (context, index) {
          final service = personalServices[index];
          final emoji = service['emoji'] as String;
          final name = service['name'] as String;
          final bgColor = service['color'] as Color;
          final iconPath = getCategoryIcon(name);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceCategoryScreen(
                    categoryName: name,
                    categoryEmoji: emoji,
                    categoryIconPath: iconPath,
                    description: getCategoryDescription(name),
                    services: getServicesForCategory(name, emoji),
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
              padding: iconPath != null ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: isSmall ? 10 : 12, vertical: isSmall ? 12 : 16),
              child: iconPath != null
                  ? Stack(
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
                        SizedBox(height: isSmall ? 8 : 12),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmall ? 11 : 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
