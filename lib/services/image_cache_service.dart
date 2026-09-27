import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  static final Map<String, Image> _imageCache = {};
  static final Map<String, int> _cacheTimestamps = {};
  static const int _cacheExpiry = 86400000; // 24 hours in milliseconds

  factory ImageCacheService() {
    return _instance;
  }

  ImageCacheService._internal();

  /// Get cached image or create new one
  Future<Image> getImage(String url, {double? width, double? height}) async {
    final cacheKey = url;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check memory cache
    if (_imageCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey] ?? 0;
      if (now - timestamp < _cacheExpiry) {
        return _imageCache[cacheKey]!;
      } else {
        _imageCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    // Create new image
    final image = Image.network(
      url,
      width: width,
      height: height,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      },
    );

    // Store in memory cache
    _imageCache[cacheKey] = image;
    _cacheTimestamps[cacheKey] = now;

    return image;
  }

  /// Clear old cache entries
  void clearExpiredCache() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToRemove = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now - timestamp > _cacheExpiry) {
        keysToRemove.add(key);
      }
    });

    for (var key in keysToRemove) {
      _imageCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear all cache
  void clearAll() {
    _imageCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache size info
  Map<String, dynamic> getCacheInfo() {
    return {
      'cachedImages': _imageCache.length,
      'cacheSize': '${(_imageCache.length * 2)}MB (approx)',
    };
  }
}
