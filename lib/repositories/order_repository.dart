import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_repository.dart';

class OrderResult {
  final bool success;
  final String? orderId;
  final String? error;

  OrderResult({
    required this.success,
    this.orderId,
    this.error,
  });
}

class PaymentResult {
  final bool success;
  final String? razorpayOrderId;
  final String? error;
  final int? amountPaise; // server-verified amount actually charged (paise)

  PaymentResult({
    required this.success,
    this.razorpayOrderId,
    this.error,
    this.amountPaise,
  });
}

class OrderRepository {
  static const String API_BASE_URL = 'https://digitrixmedia.com/mahamaintainpro/api';

  /// Step 1: Create order in database
  Future<OrderResult> createOrder({
    required String userId,
    String? phoneNumber,
    required String addressId,
    required double totalAmount,
    required int serviceCount,
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
    String? couponCode,
  }) async {
    try {
      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
      final headers = SupabaseAuthRepository.staticAuthHeaders;

      debugPrint('🟠 [createOrder] token present: ${SupabaseAuthRepository.currentToken != null}');
      debugPrint('🟠 [createOrder] token value (first 20 chars): ${SupabaseAuthRepository.currentToken?.substring(0, SupabaseAuthRepository.currentToken!.length > 20 ? 20 : SupabaseAuthRepository.currentToken!.length)}...');
      debugPrint('🟠 [createOrder] headers being sent: $headers');
      debugPrint('🟠 [createOrder] request body: order_id=$orderId, address_id=$addressId, total=$totalAmount');

      final response = await http.post(
        Uri.parse('$API_BASE_URL/create-order.php'),
        headers: headers,
        body: jsonEncode({
          'order_id': orderId,
          'user_id': userId,
          'phone_number': phoneNumber ?? userId,
          'address_id': addressId,
          'total_amount': totalAmount,
          'service_count': serviceCount,
          if (scheduledDate != null) 'scheduled_date': scheduledDate.toIso8601String().split('T').first,
          if (scheduledTimeSlot != null) 'scheduled_time': scheduledTimeSlot,
          if (couponCode != null) 'coupon_code': couponCode,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('🟠 [createOrder] response status: ${response.statusCode}');
      debugPrint('🟠 [createOrder] response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return OrderResult(
            success: true,
            orderId: data['order_id'],
          );
        } else {
          return OrderResult(
            success: false,
            error: data['message'] ?? 'Failed to create order',
          );
        }
      } else {
        return OrderResult(
          success: false,
          error: 'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('🔴 [createOrder] exception: $e');
      return OrderResult(
        success: false,
        error: 'Error creating order: $e',
      );
    }
  }

  /// Step 1b: Save order items (services) to database
  Future<bool> saveOrderItems({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/save-order-items.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'items': items,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Step 1c: Assign vendor to order (notification goes to vendor app)
  Future<bool> assignVendorToOrder({
    required String orderId,
    String? vendorId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/assign-vendor-to-order.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'order_id': orderId,
          if (vendorId != null) 'vendor_id': vendorId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Step 2: Create Razorpay order. The amount is never sent from here -
  /// the server recomputes it from orderId's real order_items/coupon (see
  /// create-razorpay-order.php) so the app can't manipulate what's charged.
  Future<PaymentResult> createRazorpayOrder({
    required String orderId,
    String? receipt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/create-razorpay-order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'receipt': receipt ?? orderId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return PaymentResult(
            success: true,
            razorpayOrderId: data['order_id'],
            amountPaise: data['amount'],
          );
        } else {
          return PaymentResult(
            success: false,
            error: data['message'] ?? 'Failed to create Razorpay order',
          );
        }
      } else {
        return PaymentResult(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Error creating Razorpay order: $e',
      );
    }
  }

  /// Step 3: Verify payment after Razorpay success
  Future<OrderResult> verifyPayment({
    required String orderId,
    required String paymentId,
    String? razorpayOrderId,
    String? signature,
    String? method,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/verify-payment.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'order_id': orderId,
          'payment_id': paymentId,
          'razorpay_order_id': razorpayOrderId,
          'signature': signature,
          'method': method,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return OrderResult(
            success: true,
            orderId: data['order_id'],
          );
        } else {
          return OrderResult(
            success: false,
            error: data['message'] ?? 'Payment verification failed',
          );
        }
      } else {
        return OrderResult(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return OrderResult(
        success: false,
        error: 'Error verifying payment: $e',
      );
    }
  }

  /// Get order details
  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/get-order.php?order_id=$orderId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['order'] != null) {
          return data['order'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
