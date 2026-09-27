import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';
import '../widgets/error_retry_view.dart';

/// Society-wide view of resident service bookings - previously the
/// committee could only see complaints, never what services their
/// residents had actually booked through the app.
class SocietyServiceRequestsScreen extends StatefulWidget {
  final int societyId;
  const SocietyServiceRequestsScreen({required this.societyId, Key? key}) : super(key: key);

  @override
  State<SocietyServiceRequestsScreen> createState() => _SocietyServiceRequestsScreenState();
}

class _SocietyServiceRequestsScreenState extends State<SocietyServiceRequestsScreen> {
  List<dynamic> _requests = [];
  bool _loading = true;
  bool _hasError = false;

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
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final response = await http
          .get(
            Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/get-society-service-requests.php?society_id=${widget.societyId}'),
            headers: SupabaseAuthRepository.staticAuthHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _requests = data['requests'] ?? [];
            _loading = false;
          });
          return;
        }
      }
      setState(() {
        _loading = false;
        _hasError = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('Service Requests'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? ErrorRetryView(onRetry: _load)
              : _requests.isEmpty
                  ? Center(
                      child: Text('No service requests yet', style: TextStyle(color: Colors.grey.shade600)),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          final status = (req['current_status'] ?? 'pending').toString();
                          final label = _statusLabels[status] ?? status;
                          final color = _statusColors[status] ?? Colors.grey;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(req['order_id'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                                      child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  req['services'] ?? 'Service',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${req['resident_name'] ?? req['phone_number'] ?? ''} • Flat ${req['flat_number'] ?? '-'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 6),
                                Text('₹${req['total_amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
