import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';

class BookingScheduleScreen extends StatefulWidget {
  final String serviceTitle;
  final Function(DateTime, String) onScheduleSelected;

  const BookingScheduleScreen({
    required this.serviceTitle,
    required this.onScheduleSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  late DateTime _selectedDate;
  String? _selectedTimeSlot;
  int _selectedDayIndex = 0;

  final List<String> _timeSlots = [
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
    '07:00 PM - 09:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  List<DateTime> _getNextSevenDays() {
    final List<DateTime> days = [];
    for (int i = 1; i <= 7; i++) {
      days.add(DateTime.now().add(Duration(days: i)));
    }
    return days;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == tomorrow) {
      return 'Tomorrow';
    }

    return DateFormat('EEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final nextSevenDays = _getNextSevenDays();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        elevation: 0,
        title: const Text('Select Date & Time', style: TextStyle(fontSize: 18)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Title
              Text(
                widget.serviceTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // Date Selection
              const Text(
                'Select Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: nextSevenDays.length,
                  itemBuilder: (context, index) {
                    final date = nextSevenDays[index];
                    final isSelected = _selectedDayIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDayIndex = index;
                          _selectedDate = date;
                          _selectedTimeSlot = null; // Reset time slot
                        });
                      },
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.saffron : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.saffron : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('d').format(date),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEE').format(date).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM').format(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white70 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Time Slot Selection
              const Text(
                'Select Time Slot',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  final slot = _timeSlots[index];
                  final isSelected = _selectedTimeSlot == slot;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTimeSlot = slot;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.saffron : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.saffron : AppTheme.saffron.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          slot,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Selected Info
              if (_selectedTimeSlot != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.saffron.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Summary',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedTimeSlot!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Confirm Button
              if (_selectedTimeSlot != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onScheduleSelected(_selectedDate, _selectedTimeSlot!);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.saffron,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm Booking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (_selectedTimeSlot == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Select Time to Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
