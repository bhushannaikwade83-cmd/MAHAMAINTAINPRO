import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../repositories/auth_repository.dart';
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cart_service.dart';
import '../repositories/order_repository.dart';
import '../config/app_theme.dart';
import 'order_confirmation_screen.dart';
import 'payment_options_screen.dart';
import 'add_address_screen.dart';

class _AppColors {
  static const brand = Color(0xFFFF9A4D);
  static const brandDeep = Color(0xFFF2762B);
  static const brandSoft = Color(0xFFFFF1E4);
  static const canvas = Color(0xFFFFF9F4);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFFFCF3EA);
  static const line = Color(0xFFF0DFD0);
  static const ink = Color(0xFF2B1B10);
  static const inkSoft = Color(0xFF8A7361);
  static const onBrand = Color(0xFFFFFFFF);
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;
  late final Razorpay _razorpay;
  final _couponCtrl = TextEditingController();

  String? _appliedCoupon;
  bool _paying = false;
  List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;
  bool _loadingAddresses = true;
  double _discountAmount = 0;
  late OrderRepository _orderRepository;
  DateTime? _selectedDate;
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _orderRepository = OrderRepository();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPayError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('userPhone');
      if (userPhone == null) return;

      final url = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/get-addresses.php');
      final response = await http
          .post(
            url,
            headers: SupabaseAuthRepository.staticAuthHeaders,
            body: jsonEncode({'phone_number': userPhone}),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['addresses'] != null) {
          setState(() {
            _addresses = List<Map<String, dynamic>>.from(data['addresses']);
            if (_addresses.isNotEmpty) _selectedAddressId = _addresses[0]['id'].toString();
            _loadingAddresses = false;
          });
        }
      } else {
        setState(() => _loadingAddresses = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading addresses: $e');
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  @override
  void dispose() {
    _stagger.dispose();
    _couponCtrl.dispose();
    _razorpay.clear();
    super.dispose();
  }

  bool _applyingCoupon = false;

  Future<void> _applyCoupon(double cartTotal) async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() => _applyingCoupon = true);
    try {
      final response = await http
          .post(
            Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/apply-coupon.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code, 'cart_total': cartTotal}),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _appliedCoupon = code;
          _discountAmount = (data['discount_amount'] as num).toDouble();
          _applyingCoupon = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon applied! You saved ₹${_discountAmount.toStringAsFixed(0)}')),
        );
      } else {
        setState(() => _applyingCoupon = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Invalid coupon code')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _applyingCoupon = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not apply coupon. Please try again.')),
      );
    }
  }

  void _startPayment(double total) async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an address')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() => _paying = true);

    final cartService = Provider.of<CartService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('userPhone') ?? 'guest';

    // Step 1: Create order in database
    final firstItem = cartService.items.isNotEmpty ? cartService.items.first : null;
    final orderResult = await _orderRepository.createOrder(
      userId: userPhone,
      phoneNumber: userPhone,
      addressId: _selectedAddressId!,
      totalAmount: total,
      serviceCount: cartService.items.length,
      scheduledDate: firstItem?.selectedDate,
      scheduledTimeSlot: firstItem?.selectedTimeSlot,
      couponCode: _appliedCoupon,
    );

    if (!mounted) return;

    if (!orderResult.success) {
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order creation failed: ${orderResult.error}')),
      );
      return;
    }

    // Step 1b: Save individual service items for this order
    final orderItems = cartService.items.map((item) => {
      'service_id': item.serviceId,
      'service_name': item.serviceName,
      'category': item.categoryId,
      'price': item.price,
      'quantity': item.quantity,
    }).toList();

    await _orderRepository.saveOrderItems(
      orderId: orderResult.orderId!,
      items: orderItems,
    );

    // Step 1c: Assign vendor to order (vendor app gets notified)
    await _orderRepository.assignVendorToOrder(
      orderId: orderResult.orderId!,
    );

    // Step 2: Navigate to payment options with order details
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentOptionsScreen(
          totalAmount: total,
          orderId: orderResult.orderId!,
        ),
      ),
    ).then((result) {
      if (result != null && result['success'] == true) {
        _handlePaymentSuccess(result, orderResult.orderId!);
      }
      setState(() => _paying = false);
    });
  }

  void _handlePaymentSuccess(Map<String, dynamic> result, String orderId) async {
    // Step 3: Verify payment with backend
    final verifyResult = await _orderRepository.verifyPayment(
      orderId: orderId,
      paymentId: result['paymentId'] ?? '',
      razorpayOrderId: result['razorpayOrderId'],
      signature: result['signature'],
      method: result['method'],
    );

    if (!mounted) return;

    if (!verifyResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment verification failed: ${verifyResult.error}')),
      );
      return;
    }

    final cartService = Provider.of<CartService>(context, listen: false);
    final selectedAddr = _addresses.isNotEmpty && _selectedAddressId != null
        ? _addresses.firstWhere((a) => a['id'].toString() == _selectedAddressId, orElse: () => <String, dynamic>{})
        : <String, dynamic>{};

    final finalAmount = result['amount'] ?? ((cartService.totalPrice + 50) - _discountAmount);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          orderId: orderId,
          totalAmount: finalAmount,
          addressLabel: selectedAddr['label'] ?? 'Home',
          addressText: selectedAddr['full_address'] ?? '${selectedAddr['building_name'] ?? ''}, ${selectedAddr['area'] ?? ''}, ${selectedAddr['pincode'] ?? ''}',
          itemCount: cartService.items.length,
          items: cartService.items.map((item) => item.serviceName).toList(),
        ),
      ),
    );
    cartService.clearCart();
  }

  void _onPayError(PaymentFailureResponse r) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.canvas,
      appBar: _buildAppBar(),
      body: _loadingAddresses
          ? const Center(child: CircularProgressIndicator())
          : Consumer<CartService>(
              builder: (context, cartService, _) {
                final itemTotal = cartService.totalPrice;
                final visitFee = 50.0;
                final gstAmount = itemTotal * 0.18;
                final discount = _appliedCoupon == null ? 0.0 : _discountAmount;
                final total = itemTotal + visitFee + gstAmount - discount;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  children: [
                    _Reveal(_stagger, 0.00, child: _progressRail()),
                    const SizedBox(height: 14),
                    _Reveal(_stagger, 0.08, child: _addressCard()),
                    const SizedBox(height: 14),
                    _Reveal(_stagger, 0.16, child: _servicesCard(cartService)),
                    const SizedBox(height: 14),
                    _Reveal(_stagger, 0.24, child: _dateTimeCard()),
                    const SizedBox(height: 14),
                    _Reveal(_stagger, 0.30, child: _couponCard(itemTotal + visitFee)),
                    const SizedBox(height: 14),
                    _Reveal(_stagger, 0.38, child: _billCard(itemTotal, visitFee, gstAmount, discount, total)),
                  ],
                );
              },
            ),
      bottomNavigationBar: Consumer<CartService>(
        builder: (context, cartService, _) {
          final gst = cartService.totalPrice * 0.18;
          final total = (cartService.totalPrice + 50 + gst) - _discountAmount;
          return _payBar(total);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 62,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.maybePop(context),
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
      title: const Text('Checkout',
          style: TextStyle(
              color: _AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _AppColors.brandSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_rounded, size: 12, color: _AppColors.brandDeep),
                SizedBox(width: 6),
                Text('Secure',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _AppColors.brandDeep)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressRail() {
    Widget dot(String label, int state) {
      final active = state != 2;
      return Column(children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? _AppColors.brandDeep : _AppColors.card,
            border: Border.all(
                color: active ? _AppColors.brandDeep : _AppColors.line, width: 1.6),
          ),
          child: state == 0
              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
              : state == 1
                  ? Center(
                      child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)))
                  : null,
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? _AppColors.ink : _AppColors.inkSoft)),
      ]);
    }

    Widget bar(Color c) => Expanded(
        child: Container(
            height: 2, margin: const EdgeInsets.only(bottom: 18), color: c));

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      dot('Cart', 0),
      bar(_AppColors.brand.withOpacity(0.5)),
      dot('Payment', 1),
      bar(_AppColors.line),
      dot('Done', 2),
    ]);
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._addresses.map((addr) {
                  final id = addr['id'].toString();
                  return RadioListTile<String>(
                    value: id,
                    groupValue: _selectedAddressId,
                    activeColor: _AppColors.brandDeep,
                    title: Text('${addr['building_name'] ?? ''}, ${addr['area'] ?? ''}'),
                    subtitle: Text('PIN ${addr['pincode'] ?? ''}'),
                    onChanged: (value) {
                      setState(() => _selectedAddressId = value);
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.add_location_alt_outlined, color: _AppColors.brandDeep),
                  title: const Text('Add new address'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddAddressScreen()),
                    );
                    _loadAddresses();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _addressCard() {
    final addr = _selectedAddressId != null && _addresses.isNotEmpty
        ? _addresses.firstWhere((a) => a['id'].toString() == _selectedAddressId, orElse: () => <String, dynamic>{})
        : <String, dynamic>{};

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle(icon: Icons.place_rounded, text: 'Service address'),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _AppColors.brandSoft, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  addr['label']?.toString().toUpperCase() ?? 'HOME',
                  style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w800,
                      color: _AppColors.brandDeep),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                addr['full_address']?.toString() ?? 'Address not available',
                style: const TextStyle(
                    fontSize: 13, height: 1.5, fontWeight: FontWeight.w500, color: _AppColors.ink),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Phone: ${addr['phone_number'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: _AppColors.inkSoft),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _showAddressPicker,
            style: TextButton.styleFrom(
              backgroundColor: _AppColors.brandSoft,
              foregroundColor: _AppColors.brandDeep,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Change',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
          ),
        ]),
      ]),
    );
  }

  Widget _servicesCard(CartService cartService) {
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle(icon: Icons.receipt_long_rounded, text: 'Your services'),
        for (int i = 0; i < cartService.items.length; i++)
          _Reveal(
            _stagger,
            0.22 + i * 0.06,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _serviceRow(cartService.items[i]),
            ),
          ),
      ]),
    );
  }

  Widget _serviceRow(CartItem item) {
    return Row(children: [
      Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _AppColors.brandSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AppColors.line),
        ),
        child: Text(item.serviceIcon, style: const TextStyle(fontSize: 20)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.serviceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: _AppColors.ink)),
          Text('₹${item.totalPrice / item.quantity} / unit',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _AppColors.inkSoft)),
        ]),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 68,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (c, a) =>
              FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
          child: Text(
            '₹${item.totalPrice.toStringAsFixed(2)}',
            key: ValueKey(item.totalPrice),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _AppColors.ink),
          ),
        ),
      ),
    ]);
  }

  Widget _dateTimeCard() {
    final now = DateTime.now();
    final isToday = _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle(icon: Icons.calendar_today_rounded, text: 'Schedule'),
        const SizedBox(height: 14),
        // Date selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(30, (index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _AppColors.brandDeep : _AppColors.muted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _AppColors.brandDeep : _AppColors.line,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          index == 0 ? 'Today' : '${date.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : _AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white : _AppColors.inkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (_selectedDate != null) ...[
          const SizedBox(height: 14),
          const Divider(color: _AppColors.line, height: 1),
          const SizedBox(height: 14),
          // Time slots
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _getTimeSlots(isToday).map((slot) {
                final isSelected = _selectedSlot == slot;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSlot = slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _AppColors.brandDeep : _AppColors.muted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _AppColors.brandDeep : _AppColors.line,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : _AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ]),
    );
  }

  List<String> _getTimeSlots(bool isToday) {
    final slots = <String>[];
    final now = DateTime.now();
    final startHour = isToday ? (now.hour + 1).clamp(8, 20) : 8;
    final endHour = 20;

    for (int hour = startHour; hour < endHour; hour++) {
      final displayHour = hour > 12 ? (hour - 12).toString() : (hour == 0 ? '12' : hour.toString());
      final period = hour >= 12 ? 'PM' : 'AM';
      final nextHour = hour + 1 > 12 ? ((hour + 1) - 12).toString() : ((hour + 1) == 0 ? '12' : (hour + 1).toString());
      final nextPeriod = (hour + 1) >= 12 ? 'PM' : 'AM';
      slots.add('$displayHour:00 $period - $nextHour:00 $nextPeriod');
    }

    return slots;
  }

  Widget _couponCard(double cartTotal) {
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle(icon: Icons.local_offer_rounded, text: 'Promo code'),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _appliedCoupon == null
              ? Row(key: const ValueKey('input'), children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextField(
                        controller: _couponCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: _AppColors.ink),
                        decoration: InputDecoration(
                          hintText: 'SAVE10',
                          filled: true,
                          fillColor: _AppColors.muted,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: _AppColors.line)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: _AppColors.brand)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _applyCoupon(cartTotal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AppColors.brandDeep,
                        foregroundColor: _AppColors.onBrand,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Apply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ])
              : Container(
                  key: const ValueKey('applied'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _AppColors.brand.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, size: 20, color: _AppColors.brandDeep),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_appliedCoupon!,
                            style: const TextStyle(
                                fontSize: 14,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w800,
                                color: _AppColors.brandDeep)),
                        Text('You saved ₹${_discountAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: _AppColors.inkSoft)),
                      ]),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _appliedCoupon = null;
                        _discountAmount = 0;
                        _couponCtrl.clear();
                      }),
                      child: const Text('Remove',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
                    ),
                  ]),
                ),
        ),
      ]),
    );
  }

  Widget _billCard(double itemTotal, double visitFee, double gstAmount, double discount, double total) {
    Widget row(String label, String value, {bool accent = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w500, color: _AppColors.inkSoft)),
            Text(value,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: accent ? _AppColors.brandDeep : _AppColors.ink)),
          ]),
        );

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle(icon: Icons.account_balance_wallet_rounded, text: 'Bill details'),
        const SizedBox(height: 14),
        row('Item total', '₹${itemTotal.toStringAsFixed(2)}'),
        row('Visit & service fee', '₹${visitFee.toStringAsFixed(2)}'),
        row('GST (18%)', '₹${gstAmount.toStringAsFixed(2)}'),
        if (_appliedCoupon != null) row('Discount', '-₹${discount.toStringAsFixed(2)}', accent: true),
        const _DashedDivider(),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total payable',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _AppColors.ink)),
          Text('₹${total.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.6, color: _AppColors.brandDeep)),
        ]),
      ]),
    );
  }

  Widget _payBar(double total) {
    final canProceed = _selectedAddressId != null && _selectedDate != null && _selectedSlot != null;

    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(color: Color(0x1A6B4A2E), blurRadius: 28, offset: Offset(0, -8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Validation warnings
          if (!canProceed)
            Column(
              children: [
                if (_selectedAddressId == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, size: 14, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Please select delivery location',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                if (_selectedDate == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, size: 14, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Please select a date',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                if (_selectedSlot == null && _selectedDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, size: 14, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Please select time slot',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          _Breathe(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: canProceed
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_AppColors.brand, _AppColors.brandDeep],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                        ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: (canProceed ? _AppColors.brandDeep : Colors.grey.shade400).withOpacity(0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: (_paying || !canProceed) ? null : () => _startPayment(total),
                    child: Center(
                      child: _paying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('Pay ₹${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      color: Colors.white)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 19, color: Colors.white),
                            ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.verified_user_rounded, size: 14, color: _AppColors.inkSoft),
            SizedBox(width: 6),
            Text('Payments secured by Razorpay',
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600, color: _AppColors.inkSoft)),
          ]),
        ]),
      ),
    );
  }
}

// ---------- Reusable Widgets ----------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _AppColors.line),
          boxShadow: const [BoxShadow(color: Color(0x0F6B4A2E), blurRadius: 22, offset: Offset(0, 8))],
        ),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionTitle({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: _AppColors.brandSoft, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: _AppColors.brandDeep),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: _AppColors.ink)),
      ]);
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: LayoutBuilder(builder: (context, c) {
          const dash = 3.0, gap = 4.0;
          final count = (c.maxWidth / (dash + gap)).floor();
          return Row(
            children: List.generate(
              count,
              (_) => Container(
                  width: dash, height: 1, margin: const EdgeInsets.only(right: gap), color: _AppColors.line),
            ),
          );
        }),
      );
}

class _Reveal extends StatelessWidget {
  final AnimationController controller;
  final double start;
  final Widget child;
  const _Reveal(this.controller, this.start, {required this.child});

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start.clamp(0, 1), (start + 0.45).clamp(0, 1), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - anim.value)), child: c),
      ),
      child: child,
    );
  }
}

class _Breathe extends StatefulWidget {
  final Widget child;
  const _Breathe({required this.child});
  @override
  State<_Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<_Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.015)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      );
}
