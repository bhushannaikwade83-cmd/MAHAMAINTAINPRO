import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../models/service_request_model.dart';

class _AppColors {
  static const brand = Color(0xFFFF9A4D);
  static const brandDeep = Color(0xFFF2762B);
  static const brandSoft = Color(0xFFFFF1E4);
  static const canvas = Color(0xFFFFF9F4);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFF0DFD0);
  static const ink = Color(0xFF2B1B10);
  static const inkSoft = Color(0xFF8A7361);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
}

class LiveTrackingScreen extends StatefulWidget {
  final int requestId;
  final BookingType bookingType;
  final String serviceName;
  final Map<String, dynamic>? booking;

  const LiveTrackingScreen({
    this.requestId = 0,
    this.bookingType = BookingType.instant,
    this.serviceName = 'Service',
    this.booking,
    Key? key,
  }) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late Timer _locationTimer;
  late Timer _statusTimer;

  ServiceRequest? _request;
  Map<String, dynamic>? _liveLocation;
  bool _loading = true;
  String _statusMessage = 'Finding vendors...';
  int _etaMinutes = 0;
  double _distanceKm = 0;

  @override
  void initState() {
    super.initState();
    _fetchRequest();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchLiveLocation());
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchRequestStatus());
  }

  Future<void> _fetchRequest() async {
    try {
      final response = await http.get(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/vendor-get-requests.php?request_id=${widget.requestId}'),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['requests'] != null && data['requests'].isNotEmpty) {
          setState(() {
            _request = ServiceRequest.fromJson(data['requests'][0]);
            _loading = false;
            _updateStatusMessage();
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchLiveLocation() async {
    if (_request?.assignedVendorId == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/customer-get-live-location.php?request_id=${widget.requestId}'),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['has_location'] == true) {
          setState(() {
            _liveLocation = data['vendor_location'];
            _etaMinutes = data['eta_minutes'] ?? 0;
            _distanceKm = data['distance_km'] ?? 0;
          });
        }
      }
    } catch (e) {
      // Silent fail for polling
    }
  }

  Future<void> _fetchRequestStatus() async {
    try {
      final response = await http.get(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/vendor-get-requests.php?request_id=${widget.requestId}'),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['requests'] != null && data['requests'].isNotEmpty) {
          setState(() {
            _request = ServiceRequest.fromJson(data['requests'][0]);
            _updateStatusMessage();
          });
        }
      }
    } catch (e) {
      // Silent fail for polling
    }
  }

  void _updateStatusMessage() {
    switch (_request?.status) {
      case RequestStatus.pending:
        _statusMessage = 'Finding nearby vendors...';
        break;
      case RequestStatus.assigned:
        _statusMessage = 'Vendor assigned - heading to you';
        break;
      case RequestStatus.enRoute:
        _statusMessage = 'Vendor on the way';
        break;
      case RequestStatus.arrived:
        _statusMessage = 'Vendor arrived';
        break;
      case RequestStatus.inProgress:
        _statusMessage = 'Service in progress';
        break;
      case RequestStatus.completed:
        _statusMessage = 'Service completed';
        break;
      default:
        _statusMessage = 'Processing your request...';
    }
  }

  @override
  void dispose() {
    _locationTimer.cancel();
    _statusTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _AppColors.canvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Finding vendors nearby...'),
            ],
          ),
        ),
      );
    }

    if (_request == null) {
      return Scaffold(
        backgroundColor: _AppColors.canvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: _AppColors.line),
              const SizedBox(height: 16),
              const Text('Request not found'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _AppColors.canvas,
      appBar: AppBar(
        backgroundColor: _AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 62,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: _AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _AppColors.line),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: _AppColors.ink),
            ),
          ),
        ),
        title: const Text('Live Tracking',
            style: TextStyle(
                color: _AppColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(),
          const SizedBox(height: 14),
          if (_request!.assignedVendorId != null) ...[
            _vendorCard(),
            const SizedBox(height: 14),
            if (_liveLocation != null) _trackingCard(),
          ],
          const SizedBox(height: 14),
          _detailsCard(),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
                child: Icon(statusIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor)),
                    Text(_statusMessage,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _AppColors.ink)),
                  ],
                ),
              ),
            ],
          ),
          if (_request!.status == RequestStatus.inProgress ||
              _request!.status == RequestStatus.completed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(
                value: _request!.status == RequestStatus.completed ? 1.0 : 0.75,
                backgroundColor: _AppColors.line,
                valueColor: AlwaysStoppedAnimation(statusColor),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _vendorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vendor Details',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _AppColors.brandSoft,
                ),
                child: const Icon(Icons.person_rounded, color: _AppColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_request!.vendorName ?? 'Vendor',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _AppColors.ink)),
                    Text(_request!.vendorPhone ?? '',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _AppColors.inkSoft)),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _AppColors.brandSoft,
                ),
                child: const Icon(Icons.call_rounded, color: _AppColors.brand, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trackingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Distance & ETA',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('${_distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _AppColors.ink)),
                    const Text('Distance',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _AppColors.inkSoft)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: _AppColors.line),
              Expanded(
                child: Column(
                  children: [
                    Text('$_etaMinutes min',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _AppColors.ink)),
                    const Text('ETA',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Details',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 12),
          _detailRow('Service', widget.serviceName),
          _detailRow('Booking Type', widget.bookingType == BookingType.instant ? 'Instant' : 'Slot'),
          _detailRow('Request ID', 'REQ#${widget.requestId}'),
          if (_request!.scheduledDate != null)
            _detailRow('Scheduled', _request!.scheduledDate.toString().split(' ')[0]),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _AppColors.inkSoft)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.ink)),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_request!.status) {
      case RequestStatus.pending:
        return _AppColors.warning;
      case RequestStatus.assigned:
      case RequestStatus.enRoute:
        return _AppColors.brand;
      case RequestStatus.arrived:
      case RequestStatus.inProgress:
        return _AppColors.success;
      case RequestStatus.completed:
        return _AppColors.success;
      default:
        return _AppColors.inkSoft;
    }
  }

  IconData _getStatusIcon() {
    switch (_request!.status) {
      case RequestStatus.pending:
        return Icons.hourglass_top_rounded;
      case RequestStatus.assigned:
        return Icons.check_circle_rounded;
      case RequestStatus.enRoute:
        return Icons.directions_car_rounded;
      case RequestStatus.arrived:
        return Icons.location_on_rounded;
      case RequestStatus.inProgress:
        return Icons.construction_rounded;
      case RequestStatus.completed:
        return Icons.task_alt_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}
