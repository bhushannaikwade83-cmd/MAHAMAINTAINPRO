import 'package:flutter/material.dart';
import '../services/slot_service.dart';

class SlotPicker extends StatefulWidget {
  final int serviceId;
  final String token;
  final String baseUrl;
  final Function(int slotId, String time) onSlotSelected;

  const SlotPicker({
    Key? key,
    required this.serviceId,
    required this.token,
    required this.baseUrl,
    required this.onSlotSelected,
  }) : super(key: key);

  @override
  State<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  late SlotService slotService;
  String selectedDate = '';
  int? selectedSlotId;
  List<AvailableDate> availableDates = [];
  List<Slot> availableSlots = [];
  bool loadingDates = true;
  bool loadingSlots = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    slotService = SlotService(
      baseUrl: widget.baseUrl,
      token: widget.token,
    );
    _loadAvailableDates();
  }

  Future<void> _loadAvailableDates() async {
    setState(() {
      loadingDates = true;
      errorMessage = null;
    });

    try {
      final dates = await slotService.getAvailableDates(
        serviceId: widget.serviceId,
      );

      setState(() {
        availableDates = dates;
        if (dates.isNotEmpty) {
          selectedDate = dates[0].date;
          _loadSlots(dates[0].date);
        }
        loadingDates = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        loadingDates = false;
      });
    }
  }

  Future<void> _loadSlots(String date) async {
    setState(() {
      loadingSlots = true;
      selectedSlotId = null;
    });

    try {
      final slots = await slotService.getAvailableSlots(
        serviceId: widget.serviceId,
        date: date,
      );

      setState(() {
        availableSlots = slots;
        loadingSlots = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        loadingSlots = false;
      });
    }
  }

  void _selectSlot(Slot slot) {
    setState(() {
      selectedSlotId = slot.id;
    });

    widget.onSlotSelected(slot.id, slot.time);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Selection
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select Date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        if (loadingDates)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: availableDates.length,
              itemBuilder: (context, index) {
                final date = availableDates[index];
                final isSelected = selectedDate == date.date;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedDate = date.date);
                      _loadSlots(date.date);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDateShort(date.date),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.availableSlots} slots',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 24),

        // Time Slot Selection
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        if (loadingSlots)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else if (availableSlots.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No slots available for ${slotService.formatDate(selectedDate)}',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: availableSlots.length,
              itemBuilder: (context, index) {
                final slot = availableSlots[index];
                final isSelected = selectedSlotId == slot.id;

                return GestureDetector(
                  onTap: slot.isAvailable ? () => _selectSlot(slot) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue
                          : slot.isAvailable
                              ? Colors.white
                              : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : slot.isAvailable
                                ? Colors.grey.shade300
                                : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slotService.formatTime(slot.startTime),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slot.isAvailable ? 'Available' : 'Full',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : slot.isAvailable
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatDateShort(String date) {
    final dateTime = DateTime.parse(date);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return 'Today';
    } else if (dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    }
  }
}
