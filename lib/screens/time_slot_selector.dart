import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

class TimeSlotSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(String) onSlotSelected;
  final String? initialSlot;

  const TimeSlotSelector({
    required this.selectedDate,
    required this.onSlotSelected,
    this.initialSlot,
    Key? key,
  }) : super(key: key);

  @override
  State<TimeSlotSelector> createState() => _TimeSlotSelectorState();
}

class _TimeSlotSelectorState extends State<TimeSlotSelector> {
  List<String> availableSlots = [];
  String? selectedSlot;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    selectedSlot = widget.initialSlot;
    _loadAvailableSlots();
  }

  @override
  void didUpdateWidget(TimeSlotSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadAvailableSlots();
    }
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.get(
        '/api/v1/slots/available',
        queryParams: {
          'date': widget.selectedDate.toString().split(' ')[0],
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        List<String> slots = List<String>.from(data['slots'] ?? []);

        // Filter out past times if selected date is today
        final now = DateTime.now();
        final isToday = widget.selectedDate.year == now.year &&
            widget.selectedDate.month == now.month &&
            widget.selectedDate.day == now.day;

        if (isToday) {
          slots = slots.where((slot) {
            final slotTime = _parseSlotTime(slot);
            return slotTime.isAfter(now);
          }).toList();
        }

        setState(() {
          availableSlots = slots.isEmpty ? _getDefaultSlots(isToday) : slots;
          isLoading = false;
        });
      } else {
        setState(() {
          availableSlots = _getDefaultSlots(false);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        availableSlots = _getDefaultSlots(false);
        errorMessage = 'Could not load slots';
        isLoading = false;
      });
    }
  }

  /// Parse slot string (e.g., "10:00 AM - 11:00 AM") to DateTime for comparison
  DateTime _parseSlotTime(String slot) {
    try {
      final startTime = slot.split(' - ')[0].trim();
      final now = DateTime.now();
      final parts = startTime.split(':');
      var hour = int.parse(parts[0]);
      final minute = int.parse(parts[1].split(' ')[0]);
      final period = startTime.contains('PM') ? 'PM' : 'AM';

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        hour,
        minute,
      );
    } catch (e) {
      return DateTime.now().add(const Duration(hours: 1));
    }
  }

  /// Default slot generation (business hours: 8 AM to 8 PM)
  List<String> _getDefaultSlots(bool isToday) {
    final slots = <String>[];
    final now = DateTime.now();
    final startHour = isToday ? (now.hour + 1) : 8;
    final endHour = 20; // 8 PM

    for (int hour = startHour; hour < endHour; hour++) {
      final hourStr = hour > 12 ? (hour - 12).toString().padLeft(2, '0') : hour.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? (hour - 12).toString() : (hour == 0 ? '12' : hour.toString());

      slots.add('$displayHour:00 $period - ${(hour + 1) > 12 ? ((hour + 1) - 12).toString() : ((hour + 1) == 0 ? '12' : (hour + 1).toString())}:00 ${(hour + 1) >= 12 ? 'PM' : 'AM'}');
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Time Slot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.saffron.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Today • Only Future Times',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.saffron,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (isLoading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (availableSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.schedule,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'No slots available for this date',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          // Slots Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: availableSlots.map((slot) {
                final isSelected = selectedSlot == slot;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedSlot = slot);
                      widget.onSlotSelected(slot);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.saffron : Colors.white,
                        border: Border.all(
                          color: isSelected ? AppTheme.saffron : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            slot.split(' - ')[0].trim(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          if (!isSelected)
                            Text(
                              '₹0',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Selected slot summary
        if (selectedSlot != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected: $selectedSlot',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
