import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _apiBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api'; // Files are at /api/ not /api/vendor/

/// Creates a booking via PHP API and stores locally for offline access
Future<Map<String, dynamic>> createBooking({
  required String categoryName,
  required List<Map<String, dynamic>> services,
  required int totalPrice,
  required Map<String, String> address,
  required int customerId,
  required int serviceCategoryId,
}) async {
  try {
    // Call PHP API to create the request
    final url = Uri.parse('$_apiBaseUrl/vendor/create-instant-request.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customer_id': customerId,
        'service_id': services.isNotEmpty ? services[0]['id'] : 1,
        'service_category_id': serviceCategoryId,
        'pincode': address['pincode'] ?? '',
        'location_address': address['address'] ?? '',
        'latitude': address['latitude'] ?? '',
        'longitude': address['longitude'] ?? '',
        'description': services.map((s) => '${s['name']} x${s['quantity']}').join(', '),
        'budget': totalPrice,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to create booking');
    }

    // Build booking object from API response
    final booking = {
      'id': data['request_id'].toString(),
      'categoryName': categoryName,
      'services': services
          .map((s) => {'name': s['name'], 'quantity': s['quantity'], 'price': s['price']})
          .toList(),
      'totalPrice': totalPrice,
      'address': address,
      'status': 'PENDING',
      'timestamp': DateTime.now().toIso8601String(),
      'serverStatus': data['status'] ?? 'PENDING',
      'message': data['message'] ?? 'Service request created',
    };

    // Also store locally for offline access
    await _saveBookingLocally(booking);

    return booking;
  } catch (e) {
    throw Exception('Failed to create booking: $e');
  }
}

/// Save booking locally for offline access
Future<void> _saveBookingLocally(Map<String, dynamic> booking) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final bookings = prefs.getStringList('bookings') ?? [];
    bookings.add(jsonEncode(booking));
    await prefs.setStringList('bookings', bookings);
  } catch (e) {
    // Log but don't throw - local storage is optional
    print('Warning: Could not save booking locally: $e');
  }
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
