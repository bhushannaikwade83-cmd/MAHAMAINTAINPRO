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

      debugPrint('🔄 Fetching orders for phone: $userPhone');
      final response = await http
          .get(
            Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/get-customer-orders.php?phone=$userPhone&filter=all'),
            headers: SupabaseAuthRepository.staticAuthHeaders,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📡 HTTP Status Code: ${response.statusCode}');
      debugPrint('📄 Raw Response Body: ${response.body}');

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
        for (var i = 0; i < _orders.length; i++) {
          debugPrint('   Order $i: ${_orders[i]['order_id']} - ${_orders[i]['status']} - OTP: ${_orders[i]['completion_otp']}');
        }
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

  Color _getStatusGradientStart(String status) {
    switch (status) {
      case 'service_completed':
        return const Color(0xFF10B981);
      case 'service_started':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFF8B5CF6);
      case 'requested':
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusGradientEnd(String status) {
    switch (status) {
      case 'service_completed':
        return const Color(0xFF059669);
      case 'service_started':
        return const Color(0xFF06B6D4);
      case 'accepted':
        return const Color(0xFFA78BFA);
      case 'requested':
      case 'pending':
        return const Color(0xFFF97316);
      default:
        return Colors.grey;
    }
  }

  Widget _buildBookingCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? order['order_status'] ?? 'pending').toString();
    final statusLabel = _statusLabels[status] ?? status;
    final services = order['services']?.toString() ?? 'Service';
    final otp = order['completion_otp']?.toString() ?? '';

    final orderId = order['id'] is int ? order['id'] as int : int.tryParse('${order['id']}') ?? 0;

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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: _getStatusGradientStart(status).withOpacity(0.6),
                width: 5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order ID + Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['order_id']?.toString() ?? 'Order',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          services,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_getStatusGradientStart(status), _getStatusGradientEnd(status)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // OTP Display (if available)
              if (otp.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFF818CF8), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 14, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 8),
                      Text(
                        'OTP: $otp',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F46E5),
                          letterSpacing: 1,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
              if (otp.isNotEmpty) const SizedBox(height: 12),

              // Amount
              Text(
                '₹${order['amount'] ?? 0}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  if (status == 'pending' || status == 'requested')
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _cancelOrder(order['order_id']?.toString() ?? ''),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_getStatusGradientStart(status), _getStatusGradientEnd(status)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'View Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
