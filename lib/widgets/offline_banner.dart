import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Wraps the whole app and shows a persistent banner whenever the device
/// has no network connectivity, so a resident isn't left staring at a
/// silently-failing screen with no idea why nothing is loading.
class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({required this.child, Key? key}) : super(key: key);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (mounted) setState(() => _isOffline = offline);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.red.shade700,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
