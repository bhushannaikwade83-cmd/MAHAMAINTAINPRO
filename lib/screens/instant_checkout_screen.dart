import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/cart_service.dart';
import '../models/service_request_model.dart';
import 'payment_options_screen.dart';
import 'live_tracking_screen.dart';

class _AppColors {
  static const brand = Color(0xFFFF9A4D);
  static const brandDeep = Color(0xFFF2762B);
  static const brandSoft = Color(0xFFFFF1E4);
  static const canvas = Color(0xFFFFF9F4);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFF0DFD0);
  static const ink = Color(0xFF2B1B10);
  static const inkSoft = Color(0xFF8A7361);
  static const success = Color(0xFF10B981);
}

class InstantCheckoutScreen extends StatefulWidget {
  final int serviceId;
  final String serviceName;
  final String serviceIcon;

  const InstantCheckoutScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.serviceIcon,
  });

  @override
  State<InstantCheckoutScreen> createState() => _InstantCheckoutScreenState();
}

class _InstantCheckoutScreenState extends State<InstantCheckoutScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;
  final _descriptionCtrl = TextEditingController();

  List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;
  bool _loadingAddresses = true;
  bool _paying = false;

  double? _selectedLat;
  double? _selectedLng;
  String? _selectedPincode;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _loadAddresses();
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
            if (_addresses.isNotEmpty) {
              _selectedAddressId = _addresses[0]['id'].toString();
              _selectedPincode = _addresses[0]['pincode']?.toString();
              _selectedLat = double.tryParse(_addresses[0]['latitude']?.toString() ?? '');
              _selectedLng = double.tryParse(_addresses[0]['longitude']?.toString() ?? '');
            }
            _loadingAddresses = false;
          });
        }
      } else {
        setState(() => _loadingAddresses = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  void _handlePaymentSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('userId');
    final cartService = Provider.of<CartService>(context, listen: false);

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    if (_selectedPincode == null || _selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location information missing')),
      );
      return;
    }

    setState(() => _paying = true);

    try {
      final response = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/vendor/create-instant-request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_id': customerId,
          'service_id': widget.serviceId,
          'service_category_id': 1,
          'pincode': _selectedPincode,
          'location_address': '${_addresses.firstWhere((a) => a['id'].toString() == _selectedAddressId, orElse: () => {})['building_name'] ?? ''}, ${_addresses.firstWhere((a) => a['id'].toString() == _selectedAddressId, orElse: () => {})['area'] ?? ''}',
          'latitude': _selectedLat,
          'longitude': _selectedLng,
          'description': _descriptionCtrl.text,
          'budget': cartService.totalPrice + 50,
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final requestId = data['request_id'];
          cartService.clearCart();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LiveTrackingScreen(
                  requestId: requestId,
                  bookingType: BookingType.instant,
                  serviceName: widget.serviceName,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to create request')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
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
        title: const Text('Instant Booking',
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
                _statusBadge(),
                const SizedBox(height: 14),
                _addressCard(),
                const SizedBox(height: 14),
                _descriptionCard(),
                const SizedBox(height: 14),
                _priceSummary(),
              ],
            ),
      bottomNavigationBar: _payButton(),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDEF7EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.success),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightning_bolt_rounded, size: 14, color: _AppColors.success),
          const SizedBox(width: 6),
          const Text('Vendor arrives in ~15-20 min',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _AppColors.success)),
        ],
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
          Text('PIN ${addr['pincode'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: _AppColors.inkSoft)),
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

  Widget _priceSummary() {
    final cartService = Provider.of<CartService>(context);
    final subtotal = cartService.totalPrice;
    final visitFee = 50.0;
    final total = subtotal + visitFee;

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
          const Text('Price Breakdown',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 10),
          _priceRow('Service amount', '₹${subtotal.toStringAsFixed(0)}'),
          _priceRow('Visit fee', '₹${visitFee.toStringAsFixed(0)}'),
          Divider(color: _AppColors.line, height: 16),
          _priceRow('Total', '₹${total.toStringAsFixed(0)}', isBold: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: isBold ? _AppColors.ink : _AppColors.inkSoft)),
          Text(amount,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: _AppColors.ink)),
        ],
      ),
    );
  }

  Widget _payButton() {
    final cartService = Provider.of<CartService>(context);
    final total = (cartService.totalPrice + 50).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _paying
            ? null
            : () {
                if (_descriptionCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please describe your service needs')),
                  );
                  return;
                }
                _handlePaymentSuccess();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _AppColors.brandDeep,
          disabledBackgroundColor: _AppColors.line,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _paying
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
            : Text('Confirm & Pay ₹$total',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
