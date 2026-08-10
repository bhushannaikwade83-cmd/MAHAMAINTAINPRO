import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_theme.dart';

class BillsMaintenanceScreen extends StatefulWidget {
  final bool isCommittee;

  const BillsMaintenanceScreen({this.isCommittee = false, Key? key}) : super(key: key);

  @override
  State<BillsMaintenanceScreen> createState() => _BillsMaintenanceScreenState();
}

class _BillsMaintenanceScreenState extends State<BillsMaintenanceScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSaving = false;

  Future<List<dynamic>> _loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    final bills = prefs.getStringList('bills') ?? [];
    return bills.map((item) => jsonDecode(item)).toList();
  }

  Future<void> _addBill() async {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final bills = prefs.getStringList('bills') ?? [];

      final newBill = jsonEncode({
        'description': _descriptionController.text,
        'amount': _amountController.text,
        'status': 'Pending',
        'timestamp': DateTime.now().toString(),
      });

      bills.add(newBill);
      await prefs.setStringList('bills', bills);

      _descriptionController.clear();
      _amountController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
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

  Future<void> _deleteBill(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final bills = prefs.getStringList('bills') ?? [];
    bills.removeAt(index);
    await prefs.setStringList('bills', bills);
    setState(() {});
  }

  Future<void> _payBill(int index, String description, String amount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Pay ₹$amount for "$description"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.saffron),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final bills = prefs.getStringList('bills') ?? [];
    if (index < 0 || index >= bills.length) return;

    final bill = jsonDecode(bills[index]) as Map<String, dynamic>;
    bill['status'] = 'Paid';
    bills[index] = jsonEncode(bill);
    await prefs.setStringList('bills', bills);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('📋 Bills & Maintenance'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isCommittee) ...[
              const Text(
                'Add Maintenance Bill',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Visible to all society members once added',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Description', _descriptionController, Icons.description, hintText: 'e.g., Water Tank Cleaning'),
                      const SizedBox(height: 12),
                      _buildTextField('Amount (₹)', _amountController, Icons.currency_rupee, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _addBill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.saffron,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Add Bill',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'All Maintenance Bills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const Text(
                'Your Maintenance Bills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Uploaded and updated by your society admin',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
            ],
            FutureBuilder<List<dynamic>>(
              future: _loadBills(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bills = snapshot.data ?? [];

                if (bills.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: const [
                          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No bills uploaded yet'),
                        ],
                      ),
                    ),
                  );
                }

                double outstandingAmount = 0;
                for (var bill in bills) {
                  if (bill['status'] == 'Pending') {
                    outstandingAmount += double.tryParse(bill['amount'].toString()) ?? 0;
                  }
                }

                return Column(
                  children: [
                    Card(
                      color: outstandingAmount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.isCommittee ? 'Total Outstanding (All Members)' : 'Total Outstanding',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${outstandingAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: outstandingAmount > 0 ? Colors.orange.shade800 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        final isPending = bill['status'] == 'Pending';
                        final statusColor = isPending ? Colors.orange : Colors.green;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        bill['description'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.isCommittee)
                                      GestureDetector(
                                        onTap: () => _deleteBill(index),
                                        child: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '₹${bill['amount']} • ${bill['status']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPending && !widget.isCommittee) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _payBill(
                                        index,
                                        bill['description'] ?? '',
                                        bill['amount'].toString(),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.saffron,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: const Text(
                                        'Pay Bill Now',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
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
    String? hintText,
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
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}
