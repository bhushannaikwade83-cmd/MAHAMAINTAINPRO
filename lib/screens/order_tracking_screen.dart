import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  final String? orderTitle;

  const OrderTrackingScreen({
    required this.orderId,
    this.orderTitle,
    Key? key,
  }) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Future<Map<String, dynamic>> _orderStatusFuture;

  @override
  void initState() {
    super.initState();
    _orderStatusFuture = _fetchOrderStatus();
  }

  Future<Map<String, dynamic>> _fetchOrderStatus() async {
    try {
      final url = Uri.parse(
        'https://digitrixmedia.com/mahamaintainpro/api/get-order-status.php?order_id=${widget.orderId}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch status');
        }
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error fetching order status: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        elevation: 0,
        title: Text(
          widget.orderTitle ?? 'Order Tracking',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _orderStatusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.saffron),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading order status',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _orderStatusFuture = _fetchOrderStatus();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.saffron,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final data = snapshot.data!;
          final currentStatus = data['current_status'] ?? 'requested';
          final statusName = data['status_name'] ?? currentStatus;
          final statusHistory = List<Map<String, dynamic>>.from(data['status_history'] ?? []);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.saffron.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.saffron, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order ID',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${data['order_id']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.saffron, AppTheme.saffronDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Status',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          statusName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatusIcon(currentStatus),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Status Timeline
                  if (statusHistory.isNotEmpty) ...[
                    const Text(
                      'Status Timeline',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._buildStatusTimeline(statusHistory),
                  ] else
                    Center(
                      child: Text(
                        'No status updates yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon = Icons.info_outline;
    Color color = Colors.white;

    switch (status) {
      case 'requested':
        icon = Icons.clock_outlined;
        break;
      case 'accepted':
        icon = Icons.check_circle_outline;
        break;
      case 'technician_assigned':
        icon = Icons.person_outline;
        break;
      case 'technician_on_the_way':
        icon = Icons.directions_car_outlined;
        break;
      case 'service_started':
        icon = Icons.build_outlined;
        break;
      case 'service_completed':
        icon = Icons.check_circle;
        color = Colors.green.shade200;
        break;
      case 'cancelled':
        icon = Icons.cancel_outlined;
        color = Colors.red.shade200;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _getStatusDescription(status),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStatusTimeline(List<Map<String, dynamic>> history) {
    return List.generate(history.length, (index) {
      final item = history[index];
      final status = item['status'] ?? '';
      final changedBy = item['changed_by'] ?? 'system';
      final changedAt = item['changed_at'] ?? '';
      final remarks = item['remarks'] ?? '';

      final isLast = index == history.length - 1;
      final statusName = _getStatusDisplayName(status);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline circle
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.saffron,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.saffron.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: AppTheme.saffron.withOpacity(0.3),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Status details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(changedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (remarks.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          remarks,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) const SizedBox(height: 16),
        ],
      );
    });
  }

  String _getStatusDisplayName(String status) {
    const names = {
      'requested': '📋 Order Requested',
      'accepted': '✅ Order Accepted',
      'technician_assigned': '👨‍🔧 Technician Assigned',
      'technician_on_the_way': '🚗 Technician On The Way',
      'service_started': '🔧 Service Started',
      'service_completed': '✨ Service Completed',
      'cancelled': '❌ Order Cancelled',
      'on_hold': '⏸️ Order On Hold',
    };
    return names[status] ?? status;
  }

  String _getStatusDescription(String status) {
    const descriptions = {
      'requested': 'Your order is confirmed. Waiting for technician assignment.',
      'accepted': 'Order has been accepted by our team.',
      'technician_assigned': 'A technician has been assigned to your order.',
      'technician_on_the_way': 'Your technician is on the way to your location.',
      'service_started': 'Service work has started at your location.',
      'service_completed': 'Service has been completed successfully!',
      'cancelled': 'Order has been cancelled.',
      'on_hold': 'Order is currently on hold.',
    };
    return descriptions[status] ?? 'No description available';
  }

  String _formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hours ago';
      } else {
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return dateTime;
    }
  }
}
