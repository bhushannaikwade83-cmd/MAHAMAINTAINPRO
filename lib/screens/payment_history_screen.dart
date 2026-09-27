import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';
import '../repositories/order_repository.dart';
import 'payment_options_screen.dart';
import '../widgets/error_retry_view.dart';

const String _apiBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _loading = true;
  bool _ordersFailed = false;
  bool _billsFailed = false;
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _pendingOrders = [];
  final _orderRepository = OrderRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _ordersFailed = false;
      _billsFailed = false;
    });
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final entries = <Map<String, dynamic>>[];
    final pending = <Map<String, dynamic>>[];

    try {
      final ordersResponse = await http
          .get(
            Uri.parse('$_apiBaseUrl/get-orders.php'),
            headers: SupabaseAuthRepository.staticAuthHeaders,
          )
          .timeout(const Duration(seconds: 10));
      final ordersData = jsonDecode(ordersResponse.body);
      if (ordersData['success'] == true) {
        for (final o in ordersData['orders']) {
          if (o['payment_status'] == 'completed' ||
              o['payment_status'] == 'refunded') {
            entries.add({
              'type': 'order',
              'id': o['order_id'],
              'title': 'Home Service Booking',
              'amount': (o['total_amount'] as num?)?.toDouble() ?? 0,
              'payment_id': o['payment_id'],
              'refund_status': o['refund_status'] ?? 'none',
              'date': o['created_at'],
              'raw': o,
            });
          } else if (o['payment_status'] == 'pending') {
            pending.add({
              'order_id': o['order_id'],
              'amount': (o['total_amount'] as num?)?.toDouble() ?? 0,
              'date': o['created_at'],
            });
          }
        }
      }
    } catch (e) {
      _ordersFailed = true;
    }

    try {
      if (userId != null) {
        final billsResponse = await http
            .get(
              Uri.parse('$_apiBaseUrl/get-my-bills.php'),
              headers: SupabaseAuthRepository.staticAuthHeaders,
            )
            .timeout(const Duration(seconds: 10));
        final billsData = jsonDecode(billsResponse.body);
        if (billsData['success'] == true) {
          for (final b in billsData['bills']) {
            if (b['status'] == 'paid') {
              entries.add({
                'type': 'bill',
                'id': b['id'],
                'title':
                    'Maintenance - ${b['period_month']} (Flat ${b['flat_number']})',
                'amount': (b['amount'] as num?)?.toDouble() ?? 0,
                'payment_id': b['payment_id'],
                'refund_status': b['refund_status'] ?? 'none',
                'date': b['paid_at'] ?? b['created_at'],
                'raw': b,
              });
            }
          }
        }
      }
    } catch (e) {
      _billsFailed = true;
    }

    entries.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    pending.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    if (mounted) {
      setState(() {
        _entries = entries;
        _pendingOrders = pending;
        _loading = false;
      });
    }
  }

  Future<void> _retryPayment(Map<String, dynamic> pendingOrder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentOptionsScreen(
          totalAmount: pendingOrder['amount'],
          orderId: pendingOrder['order_id'],
        ),
      ),
    );

    if (result == null || result['success'] != true) return;

    final verifyResult = await _orderRepository.verifyPayment(
      orderId: pendingOrder['order_id'],
      paymentId: result['paymentId'] ?? '',
      razorpayOrderId: result['razorpayOrderId'],
      signature: result['signature'],
      method: result['method'],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verifyResult.success
                ? 'Payment successful!'
                : 'Payment verification failed: ${verifyResult.error}',
          ),
          backgroundColor: verifyResult.success ? Colors.green : Colors.red,
        ),
      );
    }
    await _load();
  }

  Future<void> _requestRefund(Map<String, dynamic> entry) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Refund'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Why are you requesting a refund?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/request-refund.php'),
            headers: SupabaseAuthRepository.staticAuthHeaders,
            body: jsonEncode({
              'type': entry['type'],
              'id': entry['id'],
              'reason': reasonController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to request refund');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund requested - awaiting review'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<Uint8List> _buildReceiptPdf(Map<String, dynamic> entry) async {
    final date = DateTime.tryParse(entry['date'] ?? '') ?? DateTime.now();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MahaMaintain Pro',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Payment Receipt',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              _row('Description', entry['title']),
              _row('Reference', '${entry['id']}'),
              _row(
                'Amount Paid',
                '₹${(entry['amount'] as double).toStringAsFixed(2)}',
                bold: true,
              ),
              _row('Payment ID', '${entry['payment_id'] ?? ''}'),
              _row('Date', DateFormat('d MMM yyyy, h:mm a').format(date)),
              _row(
                'Status',
                entry['refund_status'] == 'processed' ? 'REFUNDED' : 'PAID',
                bold: true,
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Thank you for your payment.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }

  pw.Widget _row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReceiptOptions(Map<String, dynamic> entry) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt'),
        content: Text(
          '₹${(entry['amount'] as double).toStringAsFixed(2)} - ${entry['title']}',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final bytes = await _buildReceiptPdf(entry);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
            child: const Text('Print / Save PDF'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final bytes = await _buildReceiptPdf(entry);
              await SharePlus.instance.share(
                ShareParams(
                  files: [
                    XFile.fromData(
                      bytes,
                      name: 'receipt_${entry['id']}.pdf',
                      mimeType: 'application/pdf',
                    ),
                  ],
                  text: 'Payment receipt - ${entry['title']}',
                ),
              );
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
        title: const Text('💳 Payment History'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _entries.isEmpty && _pendingOrders.isEmpty
                  ? (_ordersFailed && _billsFailed
                      ? ErrorRetryView(onRetry: _load)
                      : const Center(child: Text('No payments yet')))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_pendingOrders.isNotEmpty) ...[
                          const Text(
                            'Pending Payments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Payment was not completed for these orders',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._pendingOrders.map((p) {
                            final date = DateTime.tryParse(p['date'] ?? '');
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: Colors.orange.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order ${p['order_id']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (date != null)
                                            Text(
                                              DateFormat(
                                                'd MMM yyyy',
                                              ).format(date),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          Text(
                                            '₹${(p['amount'] as double).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _retryPayment(p),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.saffron,
                                      ),
                                      child: const Text(
                                        'Retry Payment',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                        if (_entries.isNotEmpty) ...[
                          const Text(
                            'Payment History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        ..._entries.map((entry) {
                          final refundStatus = entry['refund_status'];
                          final date = DateTime.tryParse(entry['date'] ?? '');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '₹${(entry['amount'] as double).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (date != null)
                                    Text(
                                      DateFormat(
                                        'd MMM yyyy, h:mm a',
                                      ).format(date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  if (refundStatus != 'none') ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (refundStatus == 'processed'
                                                    ? Colors.green
                                                    : Colors.orange)
                                                .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Refund ${refundStatus.toUpperCase()}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: refundStatus == 'processed'
                                              ? Colors.green.shade700
                                              : Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showReceiptOptions(entry),
                                        icon: const Icon(
                                          Icons.receipt_long,
                                          size: 18,
                                        ),
                                        label: const Text('Receipt'),
                                      ),
                                      if (refundStatus == 'none')
                                        TextButton(
                                          onPressed: () =>
                                              _requestRefund(entry),
                                          child: const Text('Request Refund'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
