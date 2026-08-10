import 'dart:async';
import 'package:flutter/material.dart';
import '../data/booking_store.dart';

/// Shows the assigned provider + live status for a booking. If no specific
/// booking is passed (e.g. opened from the home screen's location button),
/// it shows the most recently placed booking instead.
class LiveTrackingScreen extends StatefulWidget {
  final Map<String, dynamic>? booking;

  const LiveTrackingScreen({this.booking, Key? key}) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  Map<String, dynamic>? _booking;
  bool _loaded = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _booking = widget.booking;
      _loaded = true;
    } else {
      _loadLatest();
    }
    // Live status is time-based, so tick the UI forward while this screen
    // is open (Confirmed -> Provider Assigned -> On the Way -> Arrived).
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadLatest() async {
    final latest = await loadLatestBooking();
    if (!mounted) return;
    setState(() {
      _booking = latest;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B9B8E),
          title: const Text('Live Tracking'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No active bookings to track yet', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      );
    }

    final booking = _booking!;
    final bookedAt = DateTime.tryParse(booking['timestamp'] ?? '') ?? DateTime.now();
    final statusInfo = getBookingStatus(bookedAt);
    final providerName = booking['providerName'] ?? 'Provider';
    final providerEmoji = booking['providerEmoji'] ?? '🧑‍🔧';
    final providerRating = booking['providerRating'] ?? '4.8';
    final address = booking['address'] as Map<String, dynamic>? ?? {};
    final addressLine = [address['flat'], address['building'], address['area']]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(', ');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Teal Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Color(0xFF1B9B8E)),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Tracking',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(
                      booking['categoryName'] ?? 'Service',
                      style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Service Provider Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F5F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1B9B8E), width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1B9B8E), width: 2),
                      ),
                      child: Text(providerEmoji, style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      providerName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '⭐ $providerRating',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    if (addressLine.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '📍 $addressLine',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        statusInfo.label,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: statusInfo.color),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Booking Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Progress',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressItem(
                    number: '1',
                    title: 'Booking Confirmed',
                    subtitle: _formatTime(bookedAt),
                    isCompleted: statusInfo.step >= 1,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressItem(
                    number: '2',
                    title: 'Provider Assigned',
                    subtitle: '$providerName • ⭐ $providerRating',
                    isCompleted: statusInfo.step >= 2,
                    isInProgress: statusInfo.step == 2,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressItem(
                    number: '3',
                    title: 'On the Way',
                    subtitle: statusInfo.step >= 3 ? 'Heading to your address' : 'Waiting',
                    isCompleted: statusInfo.step >= 3,
                    isInProgress: statusInfo.step == 3,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressItem(
                    number: '4',
                    title: 'Arrived / Service in Progress',
                    subtitle: statusInfo.step >= 4 ? 'Provider has arrived' : 'Waiting for completion',
                    isCompleted: statusInfo.step >= 4,
                    isInProgress: statusInfo.step == 4,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return 'Today • $h:$m';
  }

  static Widget _buildProgressItem({
    required String number,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isInProgress = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF1B9B8E) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Text('✓', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
                  : Text(number, style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
