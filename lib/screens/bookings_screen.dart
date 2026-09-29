import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';
import 'order_tracking_screen.dart';
import 'search_list_screen.dart';
import '../widgets/error_retry_view.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  static const Map<String, String> _statusLabels = {
    'pending': 'Requested',
    'requested': 'Requested',
    'accepted': 'Accepted',
    'technician_assigned': 'Technician Assigned',
    'technician_on_the_way': 'On The Way',
    'service_started': 'In Progress',
    'service_completed': 'Completed',
    'cancelled': 'Cancelled',
    'on_hold': 'On Hold',
  };

  static const Map<String, Color> _statusColors = {
    'pending': Colors.blueGrey,
    'requested': Colors.blueGrey,
    'accepted': Colors.blue,
    'technician_assigned': Colors.indigo,
    'technician_on_the_way': Colors.purple,
    'service_started': Colors.orange,
    'service_completed': Colors.green,
    'cancelled': Colors.red,
    'on_hold': Colors.brown,
  };

  @override
  void initState() {
    super.initState();
    _load();
    // Real periodic refresh so a status change made from the technician's
    // app (accept/start/complete) shows up here without a manual pull.
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _load(silent: true);
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('userPhone');

      if (userPhone == null) {
        setState(() {
          _loading = false;
          _error = 'User phone not found';
        });
        return;
      }

      final response = await http
          .post(
            Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/get-orders.php'),
            headers: SupabaseAuthRepository.staticAuthHeaders,
            body: jsonEncode({'phone_number': userPhone}),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      final data = jsonDecode(response.body);
      debugPrint('📦 Orders API Response: ${data['success']} | Orders count: ${(data['orders'] as List?)?.length ?? 0}');

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data['orders'] ?? []);
          _loading = false;
          _error = null;
        });
        debugPrint('✅ Loaded ${_orders.length} orders for user $userPhone');
      } else if (!silent) {
        setState(() {
          _loading = false;
          _error = data['message']?.toString() ?? 'Could not load bookings';
        });
        debugPrint('❌ Error: ${_error}');
      }
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _loading = false;
          _error = 'Network error. Pull to refresh to try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Orange Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.saffron, AppTheme.saffronDark],
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings',
                      style: TextStyle(
                        fontSize: isSmall ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      readOnly: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SearchListScreen()),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Search services, society',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: ErrorRetryView(message: _error!, onRetry: () => _load()),
      );
    }

    if (_orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No bookings yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Book a service and it will show up here',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final order in _orders) ...[
          _buildBookingCard(order),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('This will cancel your order and process a refund if payment was made.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('userPhone');

      final response = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/cancel-order.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({'order_id': orderId}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _load(); // Reload bookings
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to cancel order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error cancelling order: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBookingCard(Map<String, dynamic> order) {
    final status = (order['current_status'] ?? order['order_status'] ?? 'pending').toString();
    final statusLabel = _statusLabels[status] ?? status;
    final statusColor = _statusColors[status] ?? Colors.grey;

    final items = (order['items'] as List<dynamic>? ?? [])
        .map((i) => (i as Map)['service_name']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .join(', ');

    final orderId = order['id'] is int ? order['id'] as int : int.tryParse('${order['id']}') ?? 0;
    final scheduledAt = order['scheduled_at']?.toString();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderTrackingScreen(
            orderId: orderId,
            orderTitle: order['order_id']?.toString(),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['order_id']?.toString() ?? 'Order',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 4),
                          // Show items if available, else show service_count from database
                          if (items.isNotEmpty)
                            Text(items,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)
                          else if (order['service_count'] != null)
                            Text(
                              '${order['service_count']} service${order['service_count'] > 1 ? 's' : ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          if (scheduledAt != null) ...[
                            const SizedBox(height: 4),
                            Text('🗓️ $scheduledAt', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${order['total_amount'] ?? 0}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    if (status == 'pending' || status == 'requested')
                      GestureDetector(
                        onTap: () => _cancelOrder(order['order_id']?.toString() ?? ''),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.saffron,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Track / Details',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
