import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../services/cart_service.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  String? _selectedAddress;
  String _selectedPaymentMethod = 'Razorpay';
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoadingAddresses = true;
  bool _isProcessingPayment = false;
  late Razorpay _razorpay;

  String _couponCode = '';
  bool _isApplyingCoupon = false;
  String? _appliedCoupon;
  double _discountAmount = 0;
  TextEditingController _couponController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _initializeRazorpay();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _couponController.dispose();
    _animationController.dispose();
    super.dispose();
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
              _selectedAddress = _addresses[0]['id'].toString();
            }
            _isLoadingAddresses = false;
          });
        }
      } else {
        setState(() => _isLoadingAddresses = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _applyCoupon(CartService cartService) async {
    if (_couponController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter coupon code'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isApplyingCoupon = true);

    try {
      final response = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/apply-coupon.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': _couponController.text.toUpperCase(),
          'cart_total': cartService.totalPrice + 50,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => _isApplyingCoupon = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _appliedCoupon = data['coupon_code'];
            _discountAmount = (data['discount_amount'] ?? 0).toDouble();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Coupon applied! Save ₹${_discountAmount.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isApplyingCoupon = false);
    }
  }

  void _initiatePayment(CartService cartService) async {
    if (_selectedAddress == null) return;

    setState(() => _isProcessingPayment = true);

    final totalBeforeDiscount = cartService.totalPrice + 50;
    final finalTotal = totalBeforeDiscount - _discountAmount;
    final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    try {
      final orderResponse = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/create-order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'user_id': 'guest',
          'address_id': _selectedAddress,
          'total_amount': finalTotal,
          'discount_amount': _discountAmount,
          'coupon_code': _appliedCoupon,
          'service_count': cartService.items.length,
        }),
      ).timeout(const Duration(seconds: 10));

      if (orderResponse.statusCode != 200) throw Exception('Failed to create order');

      var options = {
        'key': 'rzp_test_1DP5mmOlF5G0m1',
        'amount': (finalTotal * 100).toInt(),
        'name': 'MahaMaintain Pro',
        'description': 'Service Booking',
        'order_id': orderId,
        'prefill': {'contact': '9876543210', 'email': 'user@example.com'},
        'external': {'wallets': ['paytm']}
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessingPayment = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final cartService = Provider.of<CartService>(context, listen: false);
    final selectedAddr = _addresses.firstWhere(
      (addr) => addr['id'].toString() == _selectedAddress,
      orElse: () => {},
    );

    try {
      final verifyResponse = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/verify-payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': response.orderId,
          'payment_id': response.paymentId,
          'signature': response.signature,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => _isProcessingPayment = false);

      if (verifyResponse.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderId: response.orderId ?? 'ORD${DateTime.now().millisecondsSinceEpoch}',
              totalAmount: cartService.totalPrice + 50,
              addressLabel: selectedAddr['label'] ?? 'Home',
              addressText: '${selectedAddr['building_name'] ?? ''}, ${selectedAddr['street'] ?? ''}, ${selectedAddr['area'] ?? ''}, ${selectedAddr['pincode'] ?? ''}',
              itemCount: cartService.items.length,
            ),
          ),
        );
        cartService.clearCart();
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessingPayment = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessingPayment = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        title: const Text(
          '🛒 Checkout',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
        ),
      ),
      body: _isLoadingAddresses
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Consumer<CartService>(
                  builder: (context, cartService, _) {
                    final selectedAddr = _selectedAddress != null
                        ? _addresses.firstWhere((addr) => addr['id'].toString() == _selectedAddress, orElse: () => {})
                        : {};
                    final totalBeforeDiscount = cartService.totalPrice + 50;
                    final finalTotal = totalBeforeDiscount - _discountAmount;

                    return Column(
                      children: [
                        // Address Card
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade900, Colors.orange.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📍 Deliver To', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1)),
                              const SizedBox(height: 8),
                              Text(
                                selectedAddr['label'] ?? 'Home',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${selectedAddr['building_name'] ?? ''}, ${selectedAddr['area'] ?? ''}',
                                style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Items Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📋 Your Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
                              const SizedBox(height: 12),
                              if (cartService.items.isEmpty)
                                Center(child: Text('No items', style: TextStyle(color: Colors.grey.shade600)))
                              else
                                ...cartService.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600]),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(child: Text(item.serviceIcon, style: const TextStyle(fontSize: 24))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.serviceName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2)),
                                            Text('x${item.quantity}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      Text('₹${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.orange, letterSpacing: 0.2)),
                                    ],
                                  ),
                                )),
                            ],
                          ),
                        ),

                        // Bill Breakdown
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
                          ),
                          child: Column(
                            children: [
                              _buildBillRow('Item Total', '₹${cartService.totalPrice.toStringAsFixed(2)}'),
                              const Divider(color: Colors.orange, height: 16),
                              _buildBillRow('Delivery', '₹50.00'),
                              if (_appliedCoupon != null) Column(
                                children: [
                                  const Divider(color: Colors.orange, height: 16),
                                  _buildBillRow('Discount', '-₹${_discountAmount.toStringAsFixed(2)}', color: Colors.green),
                                ],
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.orange.shade600]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('💰 You Pay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
                                    Text('₹${finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Coupon Section
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.orange.shade900.withOpacity(0.3), Colors.orange.shade700.withOpacity(0.2)]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.local_offer, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Text('🎟️ Promo Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_appliedCoupon == null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _couponController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'SAVE10',
                                          hintStyle: TextStyle(color: Colors.grey.shade600),
                                          filled: true,
                                          fillColor: Colors.black.withOpacity(0.3),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600]),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _isApplyingCoupon ? null : () => _applyCoupon(cartService),
                                          borderRadius: BorderRadius.circular(10),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            child: _isApplyingCoupon
                                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                                : const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.withOpacity(0.3))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('✅ Applied', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green, letterSpacing: 0.2)),
                                          Text(_appliedCoupon!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green)),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _appliedCoupon = null;
                                          _discountAmount = 0;
                                          _couponController.clear();
                                        }),
                                        child: const Text('Remove', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange, letterSpacing: 0.2)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ),
      bottomSheet: Consumer<CartService>(
        builder: (context, cartService, _) {
          final totalBeforeDiscount = cartService.totalPrice + 50;
          final finalTotal = totalBeforeDiscount - _discountAmount;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(top: BorderSide(color: Colors.orange.withOpacity(0.2), width: 1)),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 12))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isProcessingPayment ? null : () => _initiatePayment(cartService),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: _isProcessingPayment
                          ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : Column(
                              children: [
                                const Text('💳 Pay Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text('₹${finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade400, letterSpacing: 0.2)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? Colors.white, letterSpacing: 0.2)),
      ],
    );
  }
}
