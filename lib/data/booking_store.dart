import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock service providers - a real backend would assign one from actual
// vendor availability/location. This just picks one at random so each
// booking gets a plausible-looking provider.
const List<Map<String, String>> _mockProviders = [
  {'name': 'Suresh Patil', 'phone': '+91 98765 43210', 'emoji': '👨‍🔧'},
  {'name': 'Rajesh Sharma', 'phone': '+91 98765 43211', 'emoji': '👨‍🔧'},
  {'name': 'Anil Singh', 'phone': '+91 98765 43212', 'emoji': '🧑‍🔧'},
  {'name': 'Priya Deshmukh', 'phone': '+91 98765 43213', 'emoji': '👩‍🔧'},
  {'name': 'Vikram Joshi', 'phone': '+91 98765 43214', 'emoji': '👨‍🔧'},
];

/// Creates and persists a booking, returns the saved record (with provider
/// assigned) so the caller can show a confirmation right away.
Future<Map<String, dynamic>> createBooking({
  required String categoryName,
  required List<Map<String, dynamic>> services,
  required int totalPrice,
  required Map<String, String> address,
}) async {
  final provider = _mockProviders[Random().nextInt(_mockProviders.length)];
  final booking = {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'categoryName': categoryName,
    'services': services
        .map((s) => {'name': s['name'], 'quantity': s['quantity'], 'price': s['price']})
        .toList(),
    'totalPrice': totalPrice,
    'address': address,
    'providerName': provider['name'],
    'providerPhone': provider['phone'],
    'providerEmoji': provider['emoji'],
    'providerRating': (4.5 + Random().nextDouble() * 0.4).toStringAsFixed(1),
    'timestamp': DateTime.now().toIso8601String(),
  };

  final prefs = await SharedPreferences.getInstance();
  final bookings = prefs.getStringList('bookings') ?? [];
  bookings.add(jsonEncode(booking));
  await prefs.setStringList('bookings', bookings);
  return booking;
}

Future<List<Map<String, dynamic>>> loadBookings() async {
  final prefs = await SharedPreferences.getInstance();
  final bookings = prefs.getStringList('bookings') ?? [];
  return bookings.reversed.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
}

/// Most recently placed booking, or null if none exist yet.
Future<Map<String, dynamic>?> loadLatestBooking() async {
  final bookings = await loadBookings();
  return bookings.isEmpty ? null : bookings.first;
}

class BookingStatusInfo {
  final String label;
  final Color color;
  final int step; // 1-4, drives the progress list in Live Tracking
  const BookingStatusInfo(this.label, this.color, this.step);
}

/// Deterministic, time-based "live" status - no backend needed. Ticks
/// through Confirmed -> Provider Assigned -> On the Way -> Arrived over a
/// few minutes so it's actually visible while testing, not a 45-minute wait.
BookingStatusInfo getBookingStatus(DateTime bookedAt) {
  final elapsed = DateTime.now().difference(bookedAt);
  if (elapsed.inSeconds < 15) return const BookingStatusInfo('Confirmed', Colors.blue, 1);
  if (elapsed.inSeconds < 45) return const BookingStatusInfo('Provider Assigned', Colors.orange, 2);
  if (elapsed.inMinutes < 2) return const BookingStatusInfo('On the Way', Colors.purple, 3);
  if (elapsed.inMinutes < 5) return const BookingStatusInfo('Arrived', Colors.teal, 4);
  return const BookingStatusInfo('Completed', Colors.green, 4);
}
