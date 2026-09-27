import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Shows a single Society Photos grid item full-size.
/// Either [imageBytes] (a real shared photo) or [emoji]+[bgColor]
/// (a demo/seed card) is provided, never both.
class PhotoDetailScreen extends StatelessWidget {
  final String title;
  final Uint8List? imageBytes;
  final String? emoji;
  final Color? bgColor;
  final String? subtitle;

  const PhotoDetailScreen({
    required this.title,
    this.imageBytes,
    this.emoji,
    this.bgColor,
    this.subtitle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: Text(title, overflow: TextOverflow.ellipsis),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: imageBytes != null
                  ? InteractiveViewer(
                      child: Image.memory(imageBytes!, fit: BoxFit.contain),
                    )
                  : Container(
                      width: double.infinity,
                      color: bgColor ?? Colors.grey.shade200,
                      child: Center(
                        child: Text(
                          emoji ?? '🖼️',
                          style: const TextStyle(fontSize: 96),
                        ),
                      ),
                    ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
