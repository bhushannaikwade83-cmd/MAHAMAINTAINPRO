import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ApprovalPendingScreen extends StatelessWidget {
  final String secretaryName;
  final String secretaryPhone;
  final VoidCallback? onRetry;

  const ApprovalPendingScreen({
    required this.secretaryName,
    required this.secretaryPhone,
    this.onRetry,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 24,
                16,
                40,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.saffron,
                    AppTheme.saffron.withOpacity(0.85),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Approval Pending',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your society registration is under review',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Registration details card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Secretary Name',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    secretaryName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phone Number',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    secretaryPhone,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBE6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_rounded,
                              size: 20,
                              color: Color(0xFFFFA500),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'What happens next?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Our admin team will verify your details\n'
                          '• You\'ll receive approval within 24-48 hours\n'
                          '• Once approved, you can access the full society dashboard\n'
                          '• Check back regularly for updates',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Retry button
                  if (onRetry != null)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onRetry,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.saffron,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.refresh_rounded, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Check Status Again',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
