/// Mock data for testing

class MockCartData {
  static Map<String, dynamic> validCart() => {
    'success': true,
    'cart_id': 'CART_9773609077_001',
    'item_count': 2,
    'items': [
      {
        'id': 1,
        'service_id': 1,
        'service_name': 'AC Service',
        'package_name': 'Premium',
        'quantity': 1,
        'unit_price': 799.00,
        'item_subtotal': 1298.00,
        'addons': [
          {
            'addon_id': 1,
            'addon_name': 'Gas Refill',
            'addon_price': 499.00
          }
        ]
      },
      {
        'id': 2,
        'service_id': 2,
        'service_name': 'Plumbing',
        'package_name': 'Standard',
        'quantity': 1,
        'unit_price': 499.00,
        'item_subtotal': 499.00,
        'addons': []
      }
    ],
    'pricing': mockPricing()
  };

  static Map<String, dynamic> emptyCart() => {
    'success': true,
    'cart_id': 'CART_9773609077_001',
    'item_count': 0,
    'items': [],
    'pricing': {
      'items_subtotal': 0.00,
      'addons_total': 0.00,
      'service_fee': 0.00,
      'travel_fee': 0.00,
      'tax_amount': 0.00,
      'discount_amount': 0.00,
      'total': 0.00,
      'currency': 'INR'
    }
  };
}

class MockCheckoutData {
  static Map<String, dynamic> validCheckout() => {
    'success': true,
    'checkout_id': 'CHECKOUT_9773609077_1727000000',
    'cart_id': 'CART_9773609077_001',
    'pricing': mockPricing(),
    'expires_in_minutes': 15
  };

  static Map<String, dynamic> paymentOrder() => {
    'success': true,
    'checkout_id': 'CHECKOUT_9773609077_1727000000',
    'razorpay_order_id': 'order_9Aqbb3N1ORweVi',
    'amount': 1359.00,
    'currency': 'INR',
    'key': 'rzp_live_xxxxxxxxxxxxx'
  };

  static Map<String, dynamic> verifiedPayment() => {
    'success': true,
    'booking_id': 'BOOKING_9773609077_1727000000',
    'order_id': 'ORDER_9773609077_1727000000',
    'payment_id': 'pay_9Aqbb3N1ORweVi',
    'status': 'confirmed'
  };

  static Map<String, dynamic> checkoutStatus() => {
    'success': true,
    'checkout_id': 'CHECKOUT_9773609077_1727000000',
    'status': 'payment_verified',
    'cart_id': 'CART_9773609077_001',
    'scheduled_date': '2026-09-30',
    'payment_amount': 1359.00,
    'created_at': '2026-09-29 14:00:00',
    'expires_at': '2026-09-29 14:15:00',
    'is_expired': false,
    'booking_id': 'BOOKING_9773609077_1727000000',
    'booking_status': 'confirmed',
    'payment_id': 'pay_9Aqbb3N1ORweVi'
  };
}

class MockSlotData {
  static List<Map<String, dynamic>> availableDates() => [
    {'date': '2026-09-30', 'available_slots': 5},
    {'date': '2026-10-01', 'available_slots': 8},
    {'date': '2026-10-02', 'available_slots': 3},
    {'date': '2026-10-03', 'available_slots': 12},
    {'date': '2026-10-04', 'available_slots': 6},
  ];

  static List<Map<String, dynamic>> availableSlots() => [
    {
      'id': 1,
      'date': '2026-09-30',
      'time': '10:00 AM - 11:00 AM',
      'start_time': '10:00:00',
      'end_time': '11:00:00',
      'available': 1,
      'booked': 2,
      'capacity': 3
    },
    {
      'id': 2,
      'date': '2026-09-30',
      'time': '11:00 AM - 12:00 PM',
      'start_time': '11:00:00',
      'end_time': '12:00:00',
      'available': 1,
      'booked': 2,
      'capacity': 3
    },
    {
      'id': 3,
      'date': '2026-09-30',
      'time': '2:00 PM - 3:00 PM',
      'start_time': '14:00:00',
      'end_time': '15:00:00',
      'available': 0,
      'booked': 3,
      'capacity': 3
    },
  ];

  static Map<String, dynamic> fullyBookedSlot() => {
    'id': 3,
    'date': '2026-09-30',
    'time': '2:00 PM - 3:00 PM',
    'start_time': '14:00:00',
    'end_time': '15:00:00',
    'available': 0,
    'booked': 3,
    'capacity': 3
  };
}

class MockLocationData {
  static Map<String, dynamic> serviceableLocation() => {
    'success': true,
    'service_id': 1,
    'pincode': '400076',
    'serviceable': true,
    'details': {
      'location': 'Powai',
      'travel_fee': 0.00,
      'tax_rate': 18,
      'available_hours': {
        'from': '08:00:00',
        'to': '22:00:00'
      }
    },
    'message': 'Service available'
  };

  static Map<String, dynamic> unserviceableLocation() => {
    'success': false,
    'service_id': 1,
    'pincode': '999999',
    'serviceable': false,
    'message': 'Service not available in your area'
  };

  static Map<String, dynamic> outsideBusinessHours() => {
    'success': false,
    'service_id': 1,
    'pincode': '400076',
    'serviceable': false,
    'message': 'Service available 08:00 AM - 10:00 PM'
  };
}

class MockCancellationData {
  static Map<String, dynamic> cancellationPolicy100Percent() => {
    'success': true,
    'booking_id': 'BOOKING_123_456',
    'hours_until_service': 48.5,
    'original_amount': 1359.00,
    'applicable_policy': 'More than 24 hours',
    'refund_percent': 100,
    'estimated_refund': 1359.00,
    'all_policies': [
      {'hours': 24, 'refund_percent': 100, 'condition': 'More than 24 hours'},
      {'hours': 6, 'refund_percent': 80, 'condition': '6-24 hours'},
      {'hours': 2, 'refund_percent': 50, 'condition': '2-6 hours'},
      {'hours': 0, 'refund_percent': 0, 'condition': 'Less than 2 hours'},
    ]
  };

  static Map<String, dynamic> cancellationPolicy50Percent() => {
    'success': true,
    'booking_id': 'BOOKING_123_456',
    'hours_until_service': 4.0,
    'original_amount': 1359.00,
    'applicable_policy': '2-6 hours',
    'refund_percent': 50,
    'estimated_refund': 679.50,
  };

  static Map<String, dynamic> cancellationPolicy0Percent() => {
    'success': true,
    'booking_id': 'BOOKING_123_456',
    'hours_until_service': 1.0,
    'original_amount': 1359.00,
    'applicable_policy': 'Less than 2 hours',
    'refund_percent': 0,
    'estimated_refund': 0.00,
  };

  static Map<String, dynamic> cancellationResult() => {
    'success': true,
    'booking_id': 'BOOKING_123_456',
    'status': 'cancelled',
    'refund_id': 'REFUND_9773609077_1727000000',
    'refund_amount': 1359.00,
    'message': 'Booking cancelled. Refund of ₹1,359.00 will be processed.'
  };
}

class MockErrorResponses {
  static Map<String, dynamic> checkoutExpired() => {
    'success': false,
    'message': 'Checkout session expired'
  };

  static Map<String, dynamic> slotFullyBooked() => {
    'success': false,
    'message': 'Slot fully booked'
  };

  static Map<String, dynamic> serviceUnavailable() => {
    'success': false,
    'message': 'Service not available in your area'
  };

  static Map<String, dynamic> invalidSignature() => {
    'success': false,
    'message': 'Invalid payment signature'
  };

  static Map<String, dynamic> networkTimeout() => {
    'success': false,
    'message': 'Network timeout. Please try again.'
  };

  static Map<String, dynamic> unauthorized() => {
    'success': false,
    'message': 'Unauthorized access'
  };

  static Map<String, dynamic> serverError() => {
    'success': false,
    'message': 'Server error. Please try again later.'
  };
}

Map<String, dynamic> mockPricing() => {
  'items_subtotal': 1298.00,
  'addons_total': 499.00,
  'service_fee': 0.00,
  'travel_fee': 50.00,
  'tax_rate': 18.00,
  'tax_amount': 211.00,
  'discount_amount': 0.00,
  'total': 1559.00,
  'currency': 'INR'
};

class MockRazorpayResponse {
  static Map<String, dynamic> successPayment() => {
    'razorpay_order_id': 'order_9Aqbb3N1ORweVi',
    'razorpay_payment_id': 'pay_9Aqbb3N1ORweVi',
    'razorpay_signature': '9ef4dffbfd84f1318f6739a3ce19f9d85851857ae648f114332d8401e0949a3d'
  };

  static Map<String, dynamic> failedPayment() => {
    'error': 'payment_failed',
    'description': 'Payment processing failed'
  };
}
