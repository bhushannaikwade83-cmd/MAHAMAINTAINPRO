class TimeSlot {
  final int id;
  final String label;
  final String startTime;
  final String endTime;
  final double basePrice;
  final int availableSlots;
  final bool isAvailable;

  TimeSlot({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.basePrice,
    required this.availableSlots,
    required this.isAvailable,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? 0,
      label: json['label'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      basePrice: json['base_price'] != null ? double.tryParse(json['base_price'].toString()) ?? 0.0 : 0.0,
      availableSlots: json['available_slots'] ?? 0,
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
    );
  }
}
