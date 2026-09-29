import 'package:http/http.dart' as http;
import 'dart:convert';

class CancellationPolicy {
  final String bookingId;
  final double hoursUntilService;
  final double originalAmount;
  final String applicablePolicy;
  final int refundPercent;
  final double estimatedRefund;
  final bool canCancel;
  final String reason;

  CancellationPolicy({
    required this.bookingId,
    required this.hoursUntilService,
    required this.originalAmount,
    required this.applicablePolicy,
    required this.refundPercent,
    required this.estimatedRefund,
    required this.canCancel,
    required this.reason,
  });

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    final refundPercent = json['refund_percent'] as int;
    return CancellationPolicy(
      bookingId: json['booking_id'],
      hoursUntilService: (json['hours_until_service'] as num).toDouble(),
      originalAmount: (json['original_amount'] as num).toDouble(),
      applicablePolicy: json['applicable_policy'],
      refundPercent: refundPercent,
      estimatedRefund: (json['estimated_refund'] as num).toDouble(),
      canCancel: refundPercent > 0,
      reason: refundPercent == 0
          ? 'Booking is within 2 hours of scheduled time. No refund eligible.'
          : 'You can cancel this booking',
    );
  }

  String get formattedAmount => '₹${originalAmount.toStringAsFixed(2)}';
  String get formattedRefund => '₹${estimatedRefund.toStringAsFixed(2)}';
  String get hoursDisplay => '${hoursUntilService.toStringAsFixed(1)} hours';
}

class CancellationService {
  final String baseUrl;
  final String token;

  CancellationService({required this.baseUrl, required this.token});

  Future<CancellationPolicy> getCancellationPolicy({
    required String bookingId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/bookings/policy?booking_id=$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CancellationPolicy.fromJson(data);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to get policy');
      }
    } catch (e) {
      throw Exception('Error getting cancellation policy: $e');
    }
  }

  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      // First check if cancellation is allowed
      final policy = await getCancellationPolicy(bookingId: bookingId);

      if (!policy.canCancel) {
        throw Exception(policy.reason);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/bookings/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': bookingId,
          'reason': reason ?? 'User initiated cancellation',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Cancellation failed');
      }
    } catch (e) {
      throw Exception('Error cancelling booking: $e');
    }
  }

  String getRefundMessage(int refundPercent) {
    switch (refundPercent) {
      case 100:
        return 'Full refund (100%) will be processed';
      case 80:
        return '80% refund will be processed';
      case 50:
        return '50% refund will be processed';
      case 0:
        return 'No refund eligible';
      default:
        return 'Refund will be processed as per policy';
    }
  }

  String getPolicyDescription(String policy) {
    if (policy.contains('24')) return 'More than 24 hours before service';
    if (policy.contains('6')) return '6-24 hours before service';
    if (policy.contains('2')) return '2-6 hours before service';
    return 'Less than 2 hours before service';
  }

  Color getPolicyColor(int refundPercent) {
    if (refundPercent == 100) return Color(0xFF4CAF50); // Green
    if (refundPercent == 80) return Color(0xFF8BC34A); // Light Green
    if (refundPercent == 50) return Color(0xFFFFC107); // Amber
    return Color(0xFFF44336); // Red
  }
}

// Placeholder for Color import
class Color {
  final int value;
  Color(this.value);
}
