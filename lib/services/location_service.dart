import 'package:http/http.dart' as http;
import 'dart:convert';

class ServiceableLocation {
  final int serviceId;
  final String location;
  final String pincode;
  final double travelFee;
  final int taxRate;
  final String availableFrom;
  final String availableUntil;
  final bool serviceable;
  final String? message;

  ServiceableLocation({
    required this.serviceId,
    required this.location,
    required this.pincode,
    required this.travelFee,
    required this.taxRate,
    required this.availableFrom,
    required this.availableUntil,
    required this.serviceable,
    this.message,
  });

  factory ServiceableLocation.fromJson(Map<String, dynamic> json) {
    return ServiceableLocation(
      serviceId: json['service_id'],
      location: json['serviceable'] ? (json['details']?['location'] ?? 'Unknown') : 'Not Available',
      pincode: json['pincode'] ?? '',
      travelFee: double.parse((json['details']?['travel_fee'] ?? 0).toString()),
      taxRate: int.parse((json['details']?['tax_rate'] ?? 18).toString()),
      availableFrom: json['details']?['available_hours']?['from'] ?? '00:00:00',
      availableUntil: json['details']?['available_hours']?['to'] ?? '23:59:59',
      serviceable: json['serviceable'] ?? false,
      message: json['message'],
    );
  }

  bool get isTimeAvailable {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    return currentTime.compareTo(availableFrom) >= 0 && currentTime.compareTo(availableUntil) <= 0;
  }

  String get formattedTravelFee => '₹${travelFee.toStringAsFixed(0)}';
  String get formattedTaxRate => '$taxRate%';
  String get businessHours => '$availableFrom - $availableUntil';
}

class LocationService {
  final String baseUrl;
  final String token;

  LocationService({required this.baseUrl, required this.token});

  Future<ServiceableLocation> checkServiceability({
    required int serviceId,
    required String pincode,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/locations/check?service_id=$serviceId&pincode=$pincode'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        final data = jsonDecode(response.body);
        return ServiceableLocation.fromJson(data);
      } else {
        throw Exception('Failed to check serviceability');
      }
    } catch (e) {
      throw Exception('Error checking serviceability: $e');
    }
  }

  Future<ServiceableLocation> checkByLocation({
    required int serviceId,
    required int locationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/locations/check?service_id=$serviceId&location_id=$locationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        final data = jsonDecode(response.body);
        return ServiceableLocation.fromJson(data);
      } else {
        throw Exception('Failed to check serviceability');
      }
    } catch (e) {
      throw Exception('Error checking serviceability: $e');
    }
  }

  bool isValidPincode(String pincode) {
    // Indian pincode: 6 digits
    return RegExp(r'^\d{6}$').hasMatch(pincode);
  }

  bool isValidLocation(String location) {
    return location.trim().isNotEmpty && location.trim().length >= 3;
  }

  String getServiceabilityStatus(ServiceableLocation location) {
    if (!location.serviceable) {
      return location.message ?? 'Service not available in your area';
    }

    if (!location.isTimeAvailable) {
      return 'Service available ${location.businessHours}';
    }

    return 'Service available now (${location.formattedTravelFee} travel fee)';
  }
}
