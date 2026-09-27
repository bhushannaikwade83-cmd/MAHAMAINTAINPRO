import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';

const String _apiBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api';

/// Committee/secretary screen for approving or rejecting maintenance-bill
/// refund requests within their own society. Home-service order refunds
/// aren't shown here - those aren't society-scoped and can only be
/// approved by a true backend admin (via the separate admin panel), since
/// this app has no admin login flow of its own.
class ManageRefundsScreen extends StatefulWidget {
  const ManageRefundsScreen({Key? key}) : super(key: key);

  @override
  State<ManageRefundsScreen> createState() => _ManageRefundsScreenState();
}

class _ManageRefundsScreenState extends State<ManageRefundsScreen> {
  bool _loading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final societyId = prefs.getInt('societyId') ?? 1;

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiBaseUrl/get-refund-requests.php?type=bill&society_id=$societyId',
            ),
            headers: SupabaseAuthRepository.staticAuthHeaders,
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() => _requests = data['requests']);
      }
    } catch (e) {
      // Silent fail - list just shows empty
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(Map<String, dynamic> request, bool approve) async {
    double? partialAmount;

    if (approve) {
      final totalDue = (request['total_amount'] as num).toDouble();
      final amountController = TextEditingController(
        text: totalDue.toStringAsFixed(2),
      );
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve Refund'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reason: ${request['refund_reason'] ?? ''}'),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Refund Amount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm Refund'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      partialAmount = double.tryParse(amountController.text.trim());
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Refund Request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/process-refund.php'),
            headers: SupabaseAuthRepository.staticAuthHeaders,
            body: jsonEncode({
              'type': 'bill',
              'id': request['id'],
              'approve': approve,
              if (partialAmount != null) 'amount': partialAmount,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to process refund');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Refund processed successfully'
                  : 'Refund request rejected',
            ),
            backgroundColor: approve ? Colors.green : Colors.orange,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('💸 Refund Requests'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _requests.isEmpty
                  ? const Center(child: Text('No pending refund requests'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final r = _requests[index];
                        final paidAt = DateTime.tryParse(r['paid_at'] ?? '');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Flat ${r['flat_number']} • ${r['period_month']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${(r['total_amount'] as num).toStringAsFixed(2)} paid',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (paidAt != null)
                                  Text(
                                    DateFormat('d MMM yyyy').format(paidAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Reason: ${r['refund_reason'] ?? ''}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => _decide(r, false),
                                      child: const Text('Reject'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _decide(r, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.saffron,
                                      ),
                                      child: const Text(
                                        'Approve & Refund',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
