import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_theme.dart';
import 'add_payment_method_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  Future<List<dynamic>> _loadPaymentMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentMethods = prefs.getStringList('payment_methods') ?? [];
    return paymentMethods.map((item) => jsonDecode(item)).toList();
  }

  Future<void> _deletePaymentMethod(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final paymentMethods = prefs.getStringList('payment_methods') ?? [];
    paymentMethods.removeAt(index);
    await prefs.setStringList('payment_methods', paymentMethods);
    setState(() {});
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method?'),
        content: const Text('Are you sure you want to delete this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deletePaymentMethod(index);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment method deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('💳 Payment Methods'),
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _loadPaymentMethods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final paymentMethods = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Your Payment Methods',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (paymentMethods.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: const [
                          Icon(Icons.credit_card_off, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No payment methods added yet'),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    paymentMethods.length,
                    (index) {
                      final method = paymentMethods[index];
                      if (method['type'] == 'card') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.credit_card, size: 40, color: Colors.blue),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          method['name'] ?? 'Card',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '**** **** **** ${method['lastDigits'] ?? ''}',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                        Text(
                                          'Expires: ${method['expiry'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showDeleteConfirmation(index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else if (method['type'] == 'upi') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone_android, size: 40, color: Colors.green),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'UPI',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          method['upiId'] ?? '',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showDeleteConfirmation(index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPaymentMethodScreen(),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    '+ Add Payment Method',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
