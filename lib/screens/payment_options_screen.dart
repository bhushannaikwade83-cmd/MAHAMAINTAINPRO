import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  static const success = Color(0xFF16A34A);
}

class PaymentOptionsScreen extends StatefulWidget {
  final double totalAmount;
  final String orderId;
  const PaymentOptionsScreen({
    required this.totalAmount,
    required this.orderId,
    Key? key,
  }) : super(key: key);

  @override
  State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  late Razorpay _razorpay;
  String? _selectedPayment;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    Navigator.pop(context, {
      'success': true,
      'paymentId': response.paymentId,
      'method': _selectedPayment,
    });
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _processing = false);
    }
  }

  void _processPayment() {
    if (_selectedPayment == null) return;

    setState(() => _processing = true);

    if (_selectedPayment == 'googlepay') {
      _launchUPI('googlepay');
    } else if (_selectedPayment == 'phonepe') {
      _launchUPI('phonepe');
    } else if (_selectedPayment == 'bhim') {
      _launchUPI('bhim');
    } else if (_selectedPayment == 'card') {
      try {
        print('🔴 Razorpay: Opening payment...');
        print('💰 Amount: ${widget.totalAmount}');
        print('📝 Order ID: ${widget.orderId}');

        var options = {
          'key': 'rzp_live_TUUuGaHfai8zhj',
          'amount': (widget.totalAmount * 100).toInt(),
          'name': 'MahaMaintain Pro',
          'description': 'Home Service Booking',
          'order_id': widget.orderId,
          'prefill': {'contact': '', 'email': ''},
          'theme': {'color': '#F2762B'},
        };

        print('✅ Razorpay options: $options');
        _razorpay.open(options);
      } catch (e) {
        print('❌ Razorpay Error: $e');
        setState(() => _processing = false);
      }
    } else if (_selectedPayment == 'cod') {
      Navigator.pop(context, {
        'success': true,
        'paymentId': widget.orderId,
        'method': 'COD',
      });
    }
  }

  Future<void> _launchUPI(String app) async {
    final upi = 'upi://pay?pa=mahamaintainpro@upi&pn=MahaMaintain%20Pro&am=${widget.totalAmount}&tn=Service%20Booking&tr=${widget.orderId}';

    late String url;
    if (app == 'googlepay') {
      url = 'https://pay.google.com/gp/p/u/0/pay?$upi';
    } else if (app == 'phonepe') {
      url = 'phonepe://pay?$upi';
    } else if (app == 'bhim') {
      url = 'upi://pay?pa=mahamaintainpro@upi&pn=MahaMaintain%20Pro&am=${widget.totalAmount}&tn=Service%20Booking&tr=${widget.orderId}';
    }

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));

        // Save order to database
        await _saveOrderToDatabase(app.toUpperCase());

        Navigator.pop(context, {
          'success': true,
          'paymentId': widget.orderId,
          'method': app.toUpperCase(),
          'amount': widget.totalAmount,
        });
      } else {
        setState(() => _processing = false);
      }
    } catch (e) {
      setState(() => _processing = false);
    }
  }

  Future<void> _saveOrderToDatabase(String method) async {
    try {
      await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/create-order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': widget.orderId,
          'user_id': 'guest',
          'total_amount': widget.totalAmount,
          'payment_method': method,
          'payment_status': 'completed',
        }),
      );
      print('✅ Order saved to database: ${widget.orderId}');
    } catch (e) {
      print('❌ Error saving order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.canvas,
      appBar: AppBar(
        backgroundColor: _AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _AppColors.line),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18, color: _AppColors.ink),
          ),
        ),
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            color: _AppColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _AppColors.brandSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _AppColors.brand),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.inkSoft,
                    ),
                  ),
                  Text(
                    '₹${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _AppColors.brandDeep,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Digital Payments
            Text(
              'Digital Payments',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            _paymentOption(
              icon: '💳',
              title: 'Credit & Debit Card',
              subtitle: 'Visa, Mastercard, RuPay',
              value: 'card',
            ),
            const SizedBox(height: 10),
            _paymentOption(
              icon: '🔵',
              title: 'Google Pay',
              subtitle: 'Fast & secure UPI payment',
              value: 'googlepay',
            ),
            const SizedBox(height: 10),
            _paymentOption(
              icon: '💜',
              title: 'PhonePe',
              subtitle: 'Instant money transfer',
              value: 'phonepe',
            ),
            const SizedBox(height: 10),
            _paymentOption(
              icon: '🏦',
              title: 'BHIM',
              subtitle: 'Government UPI app',
              value: 'bhim',
            ),
            const SizedBox(height: 10),
            _paymentOption(
              icon: '💰',
              title: 'Wallets',
              subtitle: 'Amazon Pay, Paytm, etc',
              value: 'wallet',
              disabled: true,
            ),
            const SizedBox(height: 24),

            // Other Options
            Text(
              'Other Payment Options',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            _paymentOption(
              icon: '🏠',
              title: 'Pay on Delivery',
              subtitle: 'Pay with cash at your doorstep',
              value: 'cod',
            ),
            const SizedBox(height: 10),
            _paymentOption(
              icon: '🏦',
              title: 'Net Banking',
              subtitle: 'All major banks supported',
              value: 'netbank',
              disabled: true,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _selectedPayment != null
          ? Container(
              decoration: BoxDecoration(
                color: _AppColors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A6B4A2E),
                    blurRadius: 28,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_AppColors.brand, _AppColors.brandDeep],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _AppColors.brandDeep.withOpacity(0.35),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _processing ? null : _processPayment,
                        child: Center(
                          child: _processing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Continue to Pay',
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 19,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _paymentOption({
    required String icon,
    required String title,
    required String subtitle,
    required String value,
    bool disabled = false,
  }) {
    final isSelected = _selectedPayment == value;

    return GestureDetector(
      onTap: disabled ? null : () => setState(() => _selectedPayment = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _AppColors.brand : _AppColors.line,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _AppColors.brand.withOpacity(0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: disabled ? _AppColors.muted : _AppColors.brandSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: disabled ? _AppColors.inkSoft : _AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: _AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: disabled ? _AppColors.line : _AppColors.inkSoft.withOpacity(0.3),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
