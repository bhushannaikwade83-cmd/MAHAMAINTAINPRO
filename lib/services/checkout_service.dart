import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutService {
  final String baseUrl;
  final String token;

  CheckoutService({required this.baseUrl, required this.token});

  Future<Map<String, dynamic>> initCheckout({
    required String cartId,
    required int serviceLocationId,
    required String scheduledDate,
    required int timeSlotId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/checkout/init'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'cart_id': cartId,
          'service_location_id': serviceLocationId,
          'scheduled_date': scheduledDate,
          'time_slot_id': timeSlotId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Store checkout details locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('checkout_id', data['checkout_id']);
        await prefs.setString('pricing', jsonEncode(data['pricing']));

        return data;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Checkout failed');
      }
    } catch (e) {
      throw Exception('Error initializing checkout: $e');
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String checkoutId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/checkout/payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'checkout_id': checkoutId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Payment order creation failed');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String checkoutId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/checkout/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'checkout_id': checkoutId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Clear checkout data
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('checkout_id');
        await prefs.remove('pricing');

        return data;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Payment verification failed');
      }
    } catch (e) {
      throw Exception('Error verifying payment: $e');
    }
  }

  Future<Map<String, dynamic>> getCheckoutStatus({
    required String checkoutId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/checkout/status?checkout_id=$checkoutId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Checkout not found');
      }
    } catch (e) {
      throw Exception('Error getting checkout status: $e');
    }
  }

  Future<Map<String, dynamic>> cancelCheckout({
    required String checkoutId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/checkout/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'checkout_id': checkoutId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Cancellation failed');
      }
    } catch (e) {
      throw Exception('Error cancelling checkout: $e');
    }
  }

  Future<String?> getStoredCheckoutId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('checkout_id');
  }

  Future<Map<String, dynamic>?> getStoredPricing() async {
    final prefs = await SharedPreferences.getInstance();
    final pricingJson = prefs.getString('pricing');
    if (pricingJson != null) {
      return jsonDecode(pricingJson);
    }
    return null;
  }
}
