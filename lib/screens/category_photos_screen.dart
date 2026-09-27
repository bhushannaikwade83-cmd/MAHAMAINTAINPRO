import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import 'photo_detail_screen.dart';

/// Shows every shared photo tagged with one Photos-tab category
/// (e.g. "Ganesh Festival"), reached by tapping that category's tile.
class CategoryPhotosScreen extends StatelessWidget {
  final String categoryName;
  final String emoji;
  final Color bgColor;
  final List<dynamic> photos;

  const CategoryPhotosScreen({
    required this.categoryName,
    required this.emoji,
    required this.bgColor,
    required this.photos,
    Key? key,
  }) : super(key: key);

  String _formatDate(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.tryParse(timestamp);
    if (date == null) return '';
    return DateFormat('d MMM, h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: Text('$emoji $categoryName', overflow: TextOverflow.ellipsis),
        elevation: 0,
      ),
      body: photos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text(
                      'No photos here yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Use "Share a Photo" on the Photos tab and pick "$categoryName" to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                final bytes = base64Decode(photo['imageBase64'] as String);
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoDetailScreen(
                        title: categoryName,
                        imageBytes: bytes,
                        subtitle: _formatDate(photo['timestamp']),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
                );
              },
            ),
    );
  }
}
