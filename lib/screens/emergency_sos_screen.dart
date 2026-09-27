import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({Key? key}) : super(key: key);

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  bool _sosActivated = false;

  void _triggerSos() {
    setState(() => _sosActivated = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🚨 SOS Activated'),
        content: Text('Emergency services have been notified. Help is on the way.'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _sosActivated = false);
              Navigator.pop(context);
            },
            child: Text('OK', style: TextStyle(color: AppTheme.saffron)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.red.shade600, Colors.red.shade800],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
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
                        child: const Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Emergency SOS 🚨',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Immediate help available 24/7',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // SOS Button
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Press to Activate SOS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _sosActivated ? null : _triggerSos,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _sosActivated ? Colors.red.shade600 : Colors.red.shade500,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '🚨',
                              style: TextStyle(fontSize: 80),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _sosActivated ? 'ACTIVATED' : 'TAP SOS',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade600, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'How SOS Works',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Tap the red button to send immediate SOS alert\n• Emergency services will be contacted\n• Your location will be shared\n• Your emergency contacts will be notified',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade800,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
