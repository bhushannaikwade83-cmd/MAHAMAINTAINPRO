import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_footer.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({Key? key}) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  int _footerSelectedIndex = 4;

  final List<Map<String, dynamic>> _progressSteps = [
    {
      'step': 1,
      'title': 'Booking Confirmed',
      'subtitle': 'Today • 09:15 AM',
      'completed': true,
    },
    {
      'step': 2,
      'title': 'Professional Assigned',
      'subtitle': 'Suresh Patil • 4.9 ★',
      'completed': true,
    },
    {
      'step': 3,
      'title': 'On the way',
      'subtitle': 'Currently 1.2 km away',
      'completed': false,
      'current': true,
    },
    {
      'step': 4,
      'title': 'Service in Progress',
      'subtitle': 'We\'ll notify you soon',
      'completed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B09B),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Live Tracking',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Section with Service Provider Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00B09B).withOpacity(0.15),
                    const Color(0xFF007A6C).withOpacity(0.08),
                  ],
                ),
              ),
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Map Placeholder
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00B09B).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Icon(
                              Icons.map,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          // Animated pulse for current location
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 40 + (_pulseAnimation.value * 20),
                                height: 40 + (_pulseAnimation.value * 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00B09B)
                                        .withOpacity(1 - _pulseAnimation.value),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '📍',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Live',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00B09B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Service Person Info
                    Text(
                      'Suresh Patil • 1.2 km away',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B09B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00B09B).withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'ETA: 11 mins',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B09B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Booking Progress Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Timeline
                  Column(
                    children: List.generate(
                      _progressSteps.length,
                      (index) {
                        final step = _progressSteps[index];
                        final isCompleted = step['completed'] as bool;
                        final isCurrent = step['current'] as bool? ?? false;

                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline Dot and Line
                                Column(
                                  children: [
                                    // Dot
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCompleted
                                            ? const Color(0xFF00B09B)
                                            : isCurrent
                                                ? const Color(0xFF00B09B)
                                                : Colors.grey.shade300,
                                        boxShadow: isCompleted || isCurrent
                                            ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF00B09B,
                                                  ).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(
                                                    0,
                                                    2,
                                                  ),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: isCompleted
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 22,
                                              )
                                            : Text(
                                                '${step['step']}',
                                                style: TextStyle(
                                                  color: isCurrent
                                                      ? Colors.white
                                                      : Colors.grey.shade600,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                      ),
                                    ),
                                    // Connecting Line
                                    if (index < _progressSteps.length - 1)
                                      Container(
                                        width: 3,
                                        height: 40,
                                        color: isCompleted
                                            ? const Color(0xFF00B09B)
                                            : Colors.grey.shade300,
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                // Step Content
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step['title'] as String,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted || isCurrent
                                                ? Colors.black
                                                : Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          step['subtitle'] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (index < _progressSteps.length - 1)
                              const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: CustomFooter(
        selectedIndex: _footerSelectedIndex,
        onNavItemTap: (index) {
          setState(() => _footerSelectedIndex = index);
          if (index == 0) Navigator.pop(context, 0);
          else if (index == 1) Navigator.pop(context, 1);
          else if (index == 2) Navigator.pop(context, 2);
          else if (index == 3) Navigator.pop(context, 3);
          else if (index == 4) Navigator.pop(context, 4);
          else if (index == 5) Navigator.pop(context, 5);
        },
      ),
    );
  }
}
