import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../data/booking_store.dart';
import '../services/dashboard_tab_controller.dart';

/// Address + payment step shown after "Book Now". NOTE: "Make Payment"
/// opens Razorpay's site as a placeholder redirect - a real checkout for
/// the exact amount needs a Razorpay merchant account wired to a backend,
/// which doesn't exist yet. The booking is still saved immediately so the
/// rest of the flow (My Bookings, Live Tracking) has something real to show.
class BookingAddressScreen extends StatefulWidget {
  final String categoryName;
  final List<Map<String, dynamic>> selectedServices;
  final int totalPrice;

  const BookingAddressScreen({
    required this.categoryName,
    required this.selectedServices,
    required this.totalPrice,
    Key? key,
  }) : super(key: key);

  @override
  State<BookingAddressScreen> createState() => _BookingAddressScreenState();
}

class _BookingAddressScreenState extends State<BookingAddressScreen> {
  final _flatController = TextEditingController();
  final _buildingController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController(text: 'Mumbai');
  final _pincodeController = TextEditingController();
  String _addressType = 'Home';
  bool _processing = false;

  static const _types = ['Home', 'Work', 'Other'];

  @override
  void dispose() {
    _flatController.dispose();
    _buildingController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _makePayment() async {
    final required = [_flatController, _buildingController, _areaController, _cityController, _pincodeController];
    if (required.any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required address fields')),
      );
      return;
    }
    if (_pincodeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit pincode')),
      );
      return;
    }

    setState(() => _processing = true);

    final uri = Uri.parse('https://razorpay.com/payment-link/');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignore - still record the booking below regardless of whether the
      // browser opened, since there's no real gateway to fail against yet.
    }

    await createBooking(
      categoryName: widget.categoryName,
      services: widget.selectedServices,
      totalPrice: widget.totalPrice,
      address: {
        'flat': _flatController.text.trim(),
        'building': _buildingController.text.trim(),
        'area': _areaController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'type': _addressType,
      },
    );

    if (!mounted) return;
    setState(() => _processing = false);

    // Return to this tab's root (dropping ServiceCategoryScreen + this
    // screen off the stack), then switch the bottom nav to the Bookings
    // tab - so it's highlighted correctly there instead of "Home", and
    // switching back to Home later shows the normal home screen again.
    Navigator.popUntil(context, (route) => route.isFirst);
    DashboardTabController.switchTo(4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3ED),
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        elevation: 0,
        title: const Text('Delivery Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.selectedServices.length} service${widget.selectedServices.length == 1 ? '' : 's'} selected',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '₹${widget.totalPrice}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.saffron),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Service Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Enter the complete address for this booking', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _field('Flat / House No.*', _flatController, hint: 'e.g., A-204')),
                const SizedBox(width: 12),
                Expanded(child: _field('Pincode*', _pincodeController, hint: '400104', keyboardType: TextInputType.number, maxLength: 6)),
              ],
            ),
            const SizedBox(height: 14),
            _field('Building / Society Name*', _buildingController, hint: 'e.g., Shri Ramdev Park CHS'),
            const SizedBox(height: 14),
            _field('Area / Street*', _areaController, hint: 'e.g., Mira Road East'),
            const SizedBox(height: 14),
            _field('Landmark (optional)', _landmarkController, hint: 'e.g., Near City Mall'),
            const SizedBox(height: 14),
            _field('City*', _cityController, hint: 'e.g., Mumbai'),
            const SizedBox(height: 18),
            const Text('Address Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: _types.map((t) {
                final isSelected = _addressType == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _addressType = t),
                    selectedColor: AppTheme.saffron,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    backgroundColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _processing ? null : _makePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.saffron,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _processing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Make Payment', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !_processing,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.saffron, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
