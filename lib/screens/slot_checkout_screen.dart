import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/cart_service.dart';
import '../models/time_slot_model.dart';
import 'order_confirmation_screen.dart';

class _AppColors {
  static const brand = Color(0xFFFF9A4D);
  static const brandDeep = Color(0xFFF2762B);
  static const brandSoft = Color(0xFFFFF1E4);
  static const canvas = Color(0xFFFFF9F4);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFF0DFD0);
  static const ink = Color(0xFF2B1B10);
  static const inkSoft = Color(0xFF8A7361);
}

class SlotCheckoutScreen extends StatefulWidget {
  final int serviceId;
  final int serviceCategoryId;
  final String serviceName;
  final String serviceIcon;

  const SlotCheckoutScreen({
    super.key,
    required this.serviceId,
    required this.serviceCategoryId,
    required this.serviceName,
    required this.serviceIcon,
  });

  @override
  State<SlotCheckoutScreen> createState() => _SlotCheckoutScreenState();
}

class _SlotCheckoutScreenState extends State<SlotCheckoutScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;
  final _descriptionCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeSlot? _selectedSlot;
  List<TimeSlot> _availableSlots = [];
  List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;

  bool _loadingAddresses = true;
  bool _loadingSlots = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _loadAddresses();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  Future<void> _loadAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('userPhone');
      final url = userPhone != null
          ? 'https://digitrixmedia.com/mahamaintainpro/api/get-addresses.php?phone_number=$userPhone'
          : 'https://digitrixmedia.com/mahamaintainpro/api/get-addresses.php';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['addresses'] != null) {
          setState(() {
            _addresses = List<Map<String, dynamic>>.from(data['addresses']);
            if (_addresses.isNotEmpty) _selectedAddressId = _addresses[0]['id'].toString();
            _loadingAddresses = false;
          });
          _loadSlots();
        }
      } else {
        setState(() => _loadingAddresses = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedDate == null) return;

    setState(() => _loadingSlots = true);
    try {
      final response = await http.get(
        Uri.parse(
            'https://digitrixmedia.com/mahamaintainpro/api/get-service-time-slots.php?category_id=${widget.serviceCategoryId}&date=${_selectedDate!.toIso8601String().split('T')[0]}'),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['slots'] != null) {
          setState(() {
            _availableSlots = List<Map<String, dynamic>>.from(data['slots'])
                .map((slot) => TimeSlot.fromJson(slot))
                .toList();
            _selectedSlot = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading slots: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    if (_descriptionCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your service needs')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('userId');

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    setState(() => _confirming = true);

    try {
      final selectedAddr = _addresses.firstWhere(
        (a) => a['id'].toString() == _selectedAddressId,
        orElse: () => <String, dynamic>{},
      );

      final response = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/create-slot-request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_id': customerId,
          'service_id': widget.serviceId,
          'time_slot_id': _selectedSlot!.id,
          'pincode': selectedAddr['pincode'] ?? '',
          'location_address': '${selectedAddr['building_name'] ?? ''}, ${selectedAddr['area'] ?? ''}',
          'description': _descriptionCtrl.text,
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final cartService = Provider.of<CartService>(context, listen: false);
          cartService.clearCart();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderConfirmationScreen(
                  orderId: 'SLOT${data['request_id']}',
                  totalAmount: data['price'] ?? _selectedSlot!.basePrice,
                  addressLabel: 'Scheduled Service',
                  addressText:
                      '${_selectedDate?.toLocal().toString().split(' ')[0]} at ${_selectedSlot!.label}',
                  itemCount: 1,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to create booking')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  void dispose() {
    _stagger.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.canvas,
      appBar: AppBar(
        backgroundColor: _AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 62,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: _AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _AppColors.line),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: _AppColors.ink),
            ),
          ),
        ),
        title: const Text('Schedule Service',
            style: TextStyle(
                color: _AppColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w800)),
      ),
      body: _loadingAddresses
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                _dateSelector(),
                const SizedBox(height: 14),
                if (_loadingSlots)
                  const Center(child: CircularProgressIndicator())
                else if (_availableSlots.isEmpty)
                  _noSlotsCard()
                else
                  _slotsCard(),
                const SizedBox(height: 14),
                _addressCard(),
                const SizedBox(height: 14),
                _descriptionCard(),
                const SizedBox(height: 14),
                _priceCard(),
              ],
            ),
      bottomNavigationBar: _confirmButton(),
    );
  }

  Widget _dateSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Date',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadSlots();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: _AppColors.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null ? 'Select Date' : _selectedDate!.toString().split(' ')[0],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _AppColors.ink),
                  ),
                  const Icon(Icons.calendar_today_rounded, size: 16, color: _AppColors.brand),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Slots',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSlots.map((slot) {
              final isSelected = _selectedSlot?.id == slot.id;
              return GestureDetector(
                onTap: slot.isAvailable ? () => setState(() => _selectedSlot = slot) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _AppColors.brand : (slot.isAvailable ? _AppColors.muted : _AppColors.line),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? _AppColors.brandDeep : _AppColors.line,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(slot.label,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : _AppColors.ink)),
                      Text('₹${slot.basePrice.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : _AppColors.inkSoft)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _noSlotsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: _AppColors.line),
            const SizedBox(height: 12),
            const Text('No slots available for selected date',
                style: TextStyle(fontSize: 12, color: _AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _addressCard() {
    final addr = _selectedAddressId != null && _addresses.isNotEmpty
        ? _addresses.firstWhere((a) => a['id'].toString() == _selectedAddressId, orElse: () => <String, dynamic>{})
        : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service Location',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 8),
          Text('${addr['building_name'] ?? ''}, ${addr['area'] ?? ''}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.ink)),
        ],
      ),
    );
  }

  Widget _descriptionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service Details',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe what you need...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 8),
          if (_selectedSlot != null)
            Text('₹${_selectedSlot!.basePrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _AppColors.ink))
          else
            const Text('Select a slot', style: TextStyle(fontSize: 12, color: _AppColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _confirmButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _confirming || _selectedSlot == null ? null : _confirmBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: _AppColors.brandDeep,
          disabledBackgroundColor: _AppColors.line,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _confirming
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
            : const Text('Confirm Booking',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
