import 'package:flutter/material.dart';
import '../services/image_cache_service.dart';

class LazyImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color placeholderColor;

  const LazyImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderColor = const Color(0xFFE0E0E0),
    Key? key,
  }) : super(key: key);

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  late Future<Image> _imageFuture;
  final _imageCache = ImageCacheService();

  @override
  void initState() {
    super.initState();
    _imageFuture = _imageCache.getImage(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Image>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else if (snapshot.hasError) {
            return _buildErrorWidget();
          }
        }

        // Loading state - show placeholder
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.placeholderColor,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.grey[400]!,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[600],
      ),
    );
  }
}
