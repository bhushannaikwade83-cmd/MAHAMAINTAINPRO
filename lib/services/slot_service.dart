import 'package:http/http.dart' as http;
import 'dart:convert';

class Slot {
  final int id;
  final String date;
  final String time;
  final String startTime;
  final String endTime;
  final int available;
  final int booked;
  final int capacity;

  Slot({
    required this.id,
    required this.date,
    required this.time,
    required this.startTime,
    required this.endTime,
    required this.available,
    required this.booked,
    required this.capacity,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['id'],
      date: json['date'],
      time: json['time'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      available: json['available'],
      booked: json['booked'],
      capacity: json['capacity'],
    );
  }

  bool get isAvailable => available > 0;
}

class AvailableDate {
  final String date;
  final int availableSlots;

  AvailableDate({
    required this.date,
    required this.availableSlots,
  });

  factory AvailableDate.fromJson(Map<String, dynamic> json) {
    return AvailableDate(
      date: json['date'],
      availableSlots: json['available_slots'],
    );
  }
}

class SlotService {
  final String baseUrl;
  final String token;

  SlotService({required this.baseUrl, required this.token});

  Future<List<Slot>> getAvailableSlots({
    required int serviceId,
    required String date,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/slots/available?service_id=$serviceId&date=$date'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slots = (data['slots'] as List)
            .map((slot) => Slot.fromJson(slot))
            .toList();
        return slots;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load slots');
      }
    } catch (e) {
      throw Exception('Error loading slots: $e');
    }
  }

  Future<List<AvailableDate>> getAvailableDates({
    required int serviceId,
    int daysAhead = 30,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/slots/dates?service_id=$serviceId&days=$daysAhead'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dates = (data['available_dates'] as List)
            .map((date) => AvailableDate.fromJson(date))
            .toList();
        return dates;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load dates');
      }
    } catch (e) {
      throw Exception('Error loading dates: $e');
    }
  }

  Future<Map<String, dynamic>> checkSlotAvailability({
    required int timeSlotId,
    required String date,
  }) async {
    try {
      final slots = await getAvailableSlots(
        serviceId: 1, // Would come from cart context
        date: date,
      );

      final slot = slots.firstWhere(
        (s) => s.id == timeSlotId,
        orElse: () => throw Exception('Slot not found'),
      );

      return {
        'available': slot.isAvailable,
        'booked': slot.booked,
        'capacity': slot.capacity,
        'time': slot.time,
      };
    } catch (e) {
      throw Exception('Error checking slot: $e');
    }
  }

  String formatTime(String time24) {
    // Convert 14:30 to 2:30 PM
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];

    if (hour >= 12) {
      final displayHour = hour == 12 ? 12 : hour - 12;
      return '$displayHour:$minute PM';
    } else {
      final displayHour = hour == 0 ? 12 : hour;
      return '$displayHour:$minute AM';
    }
  }

  String formatDate(String date) {
    // Convert 2026-09-30 to Sep 30, 2026
    final dateTime = DateTime.parse(date);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}
