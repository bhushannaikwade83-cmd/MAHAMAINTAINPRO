import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Shared "something went wrong" state with a Retry button, for any screen
/// whose data load can fail (timeout, no internet, server error). Most
/// screens previously just left the user on a spinner or an empty list
/// with no way to recover short of leaving and re-entering the screen.
class ErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const ErrorRetryView({
    this.message = 'Something went wrong. Please check your connection and try again.',
    required this.onRetry,
    this.icon = Icons.cloud_off_outlined,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffron,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
