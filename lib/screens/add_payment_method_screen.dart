import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_theme.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({Key? key}) : super(key: key);

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  late TabController _tabController;
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _upiController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _addCardPayment() async {
    if (_cardNameController.text.isEmpty ||
        _cardNumberController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _cvvController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    if (_cardNumberController.text.length < 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card number must be at least 13 digits')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentMethods = prefs.getStringList('payment_methods') ?? [];

      final lastDigits = _cardNumberController.text.substring(
        _cardNumberController.text.length - 4,
      );
      final newCard = jsonEncode({
        'type': 'card',
        'name': _cardNameController.text,
        'lastDigits': lastDigits,
        'expiry': _expiryController.text,
      });

      paymentMethods.add(newCard);
      await prefs.setStringList('payment_methods', paymentMethods);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _addUPIPayment() async {
    if (_upiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI ID is required!')),
      );
      return;
    }

    if (!_upiController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid UPI ID')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentMethods = prefs.getStringList('payment_methods') ?? [];

      final newUPI = jsonEncode({
        'type': 'upi',
        'upiId': _upiController.text,
      });

      paymentMethods.add(newUPI);
      await prefs.setStringList('payment_methods', paymentMethods);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.saffron,
          title: const Text('+ Add Payment Method'),
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: '💳 Card'),
              Tab(text: '📱 UPI'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Card Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Card Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            'Card Holder Name',
                            _cardNameController,
                            Icons.person,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            'Card Number',
                            _cardNumberController,
                            Icons.credit_card,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'Expiry (MM/YY)',
                                  _expiryController,
                                  Icons.calendar_today,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  'CVV',
                                  _cvvController,
                                  Icons.lock,
                                  keyboardType: TextInputType.number,
                                  maxLength: 3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _addCardPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.saffron,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Add Card',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // UPI Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add UPI ID',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            'UPI ID (e.g., name@paytm)',
                            _upiController,
                            Icons.payment,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _addUPIPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.saffron,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Add UPI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !_isSaving,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(icon),
            counterText: '',
          ),
        ),
      ],
    );
  }
}
