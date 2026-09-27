import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';

const String _apiBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api';

class BillsMaintenanceScreen extends StatefulWidget {
  final bool isCommittee;

  const BillsMaintenanceScreen({this.isCommittee = false, Key? key}) : super(key: key);

  @override
  State<BillsMaintenanceScreen> createState() => _BillsMaintenanceScreenState();
}

class _BillsMaintenanceScreenState extends State<BillsMaintenanceScreen> {
  final _amountController = TextEditingController();
  final _dueDateDayController = TextEditingController(text: '10');
  DateTime _periodMonth = DateTime.now();
  bool _isSaving = false;
  bool _loading = true;
  List<dynamic> _bills = [];
  double _totalOutstanding = 0;
  late Razorpay _razorpay;
  Map<String, dynamic>? _payingBill;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dueDateDayController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      if (widget.isCommittee) {
        final societyId = prefs.getInt('societyId') ?? 1;
        final response = await http.get(
          Uri.parse('$_apiBaseUrl/get-flat-bills.php?society_id=$societyId'),
          headers: SupabaseAuthRepository.staticAuthHeaders,
        ).timeout(const Duration(seconds: 10));
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _bills = data['bills'];
            _totalOutstanding = (data['total_outstanding'] as num).toDouble();
          });
        }
      } else {
        final userId = prefs.getInt('userId');
        if (userId == null) return;
        final response = await http.get(
          Uri.parse('$_apiBaseUrl/get-my-bills.php'),
          headers: SupabaseAuthRepository.staticAuthHeaders,
        ).timeout(const Duration(seconds: 10));
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final bills = data['bills'] as List;
          double outstanding = 0;
          for (final b in bills) {
            if (b['status'] == 'due') outstanding += (b['total_due'] as num).toDouble();
          }
          setState(() {
            _bills = bills;
            _totalOutstanding = outstanding;
          });
        }
      }
    } catch (e) {
      // Silent fail - list just shows empty
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPeriodMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      helpText: 'Select billing month',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.saffron)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _periodMonth = picked);
  }

  Future<void> _generateBills() async {
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the maintenance amount per flat')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final societyId = prefs.getInt('societyId') ?? 1;
      final periodMonth = DateFormat('yyyy-MM').format(_periodMonth);
      final dueDay = int.tryParse(_dueDateDayController.text.trim()) ?? 10;
      final dueDate = DateFormat('yyyy-MM-dd').format(DateTime(_periodMonth.year, _periodMonth.month, dueDay));

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/generate-monthly-bills.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'society_id': societyId,
          'period_month': periodMonth,
          'amount': double.parse(_amountController.text.trim()),
          'due_date': dueDate,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to generate bills');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Bills generated'), backgroundColor: Colors.green),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _payBill(Map<String, dynamic> bill) async {
    setState(() => _payingBill = bill);
    try {
      // Amount is never sent from here - the server recomputes it from the
      // bill's real amount + live-calculated late fee (see
      // create-razorpay-order.php's bill_id path).
      final orderResponse = await http.post(
        Uri.parse('$_apiBaseUrl/create-razorpay-order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bill_id': bill['id'], 'receipt': 'bill_${bill['id']}'}),
      ).timeout(const Duration(seconds: 15));

      final orderData = jsonDecode(orderResponse.body);
      if (orderResponse.statusCode != 200 || orderData['success'] != true) {
        throw Exception(orderData['message'] ?? 'Failed to create payment order');
      }

      final options = {
        'key': 'rzp_live_TUUuGaHfai8zhj',
        'amount': orderData['amount'],
        'name': 'MahaMaintain Pro',
        'description': 'Maintenance - ${bill['period_month']} (Flat ${bill['flat_number']})',
        'order_id': orderData['order_id'],
        'theme': {'color': '#F2762B'},
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _payingBill = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final bill = _payingBill;
    if (bill == null) return;

    try {
      final verifyResponse = await http.post(
        Uri.parse('$_apiBaseUrl/pay-maintenance-bill.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'bill_id': bill['id'],
          'payment_id': response.paymentId,
          'razorpay_order_id': response.orderId,
          'signature': response.signature,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(verifyResponse.body);
      if (verifyResponse.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Payment verification failed');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!'), backgroundColor: Colors.green),
        );
        _showReceipt({...bill, 'payment_id': response.paymentId, 'status': 'paid'});
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment succeeded but verification failed: $e')),
        );
      }
    } finally {
      setState(() => _payingBill = null);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _payingBill = null);
    if (!mounted) return;

    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled'), backgroundColor: Colors.grey),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<Uint8List> _buildReceiptPdf(Map<String, dynamic> bill) async {
    final amount = (bill['amount'] as num?)?.toDouble() ?? 0;
    final lateFee = (bill['late_fee'] as num?)?.toDouble() ?? 0;
    final total = amount + lateFee;
    final paidAt = bill['paid_at'] != null ? DateTime.tryParse(bill['paid_at']) : null;

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('MahaMaintain Pro', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text('Maintenance Payment Receipt', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.SizedBox(height: 20),
              pw.Divider(),
              _receiptRow('Flat Number', '${bill['flat_number'] ?? ''}'),
              _receiptRow('Billing Period', '${bill['period_month'] ?? ''}'),
              _receiptRow('Amount', '₹${amount.toStringAsFixed(2)}'),
              if (lateFee > 0) _receiptRow('Late Fee', '₹${lateFee.toStringAsFixed(2)}'),
              pw.Divider(),
              _receiptRow('Total Paid', '₹${total.toStringAsFixed(2)}', bold: true),
              _receiptRow('Payment ID', '${bill['payment_id'] ?? ''}'),
              _receiptRow('Paid On', paidAt != null ? DateFormat('d MMM yyyy, h:mm a').format(paidAt) : DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())),
              _receiptRow('Status', 'PAID', bold: true),
              pw.SizedBox(height: 24),
              pw.Text('Thank you for your payment.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }

  pw.Widget _receiptRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  Future<void> _showReceipt(Map<String, dynamic> bill) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt'),
        content: const SizedBox(
          width: 260,
          child: Text('Your maintenance payment receipt is ready.'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final bytes = await _buildReceiptPdf(bill);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
            child: const Text('Print / Save PDF'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final bytes = await _buildReceiptPdf(bill);
              await SharePlus.instance.share(ShareParams(
                files: [XFile.fromData(bytes, name: 'receipt_${bill['id']}.pdf', mimeType: 'application/pdf')],
                text: 'Maintenance receipt - ${bill['period_month']}',
              ));
            },
            child: const Text('Share'),
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
        title: const Text('📋 Bills & Maintenance'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isCommittee) ...[
                      const Text('Generate Monthly Bills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Creates one bill per flat for the selected month',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Billing Month', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickPeriodMonth,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_month, color: AppTheme.saffron, size: 20),
                                      const SizedBox(width: 10),
                                      Text(DateFormat('MMMM yyyy').format(_periodMonth)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildTextField('Amount per Flat (₹)', _amountController, Icons.currency_rupee, keyboardType: TextInputType.number),
                              const SizedBox(height: 12),
                              _buildTextField('Due Date (day of month)', _dueDateDayController, Icons.event, keyboardType: TextInputType.number),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _isSaving ? null : _generateBills,
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
                                    : const Text('Generate Bills', style: TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('All Bills (Flat-wise)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                    ] else ...[
                      const Text('Your Maintenance Bills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Generated by your society committee',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_bills.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No bills yet'),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      Card(
                        color: _totalOutstanding > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.isCommittee ? 'Total Outstanding (All Flats)' : 'Total Outstanding',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${_totalOutstanding.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _totalOutstanding > 0 ? Colors.orange.shade800 : Colors.green.shade700,
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
                        itemCount: _bills.length,
                        itemBuilder: (context, index) {
                          final bill = _bills[index];
                          final isPaid = bill['status'] == 'paid';
                          final isOverdue = bill['is_overdue'] == true || (!isPaid && (bill['late_fee'] as num? ?? 0) > 0);
                          final statusColor = isPaid ? Colors.green : (isOverdue ? Colors.red : Colors.orange);
                          final amount = (bill['amount'] as num?)?.toDouble() ?? 0;
                          final lateFee = (bill['late_fee'] as num?)?.toDouble() ?? 0;
                          final total = amount + lateFee;

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
                                          '${bill['period_month']}${widget.isCommittee ? ' • Flat ${bill['flat_number']}' : ''}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                      '₹${total.toStringAsFixed(2)}${lateFee > 0 ? ' (incl. ₹${lateFee.toStringAsFixed(0)} late fee)' : ''} • ${isPaid ? 'PAID' : (isOverdue ? 'OVERDUE' : 'DUE')}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (bill['due_date'] != null && !isPaid) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Due by ${DateFormat('d MMM yyyy').format(DateTime.parse(bill['due_date']))}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                  if (!widget.isCommittee && !isPaid) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _payingBill != null ? null : () => _payBill(bill),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.saffron,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        child: Text(
                                          _payingBill?['id'] == bill['id'] ? 'Processing...' : 'Pay Bill Now',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (!widget.isCommittee && isPaid) ...[
                                    const SizedBox(height: 10),
                                    TextButton.icon(
                                      onPressed: () => _showReceipt(bill),
                                      icon: const Icon(Icons.receipt_long, size: 18),
                                      label: const Text('View / Share Receipt'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
