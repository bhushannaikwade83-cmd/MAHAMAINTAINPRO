import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_footer.dart';

class InstaHelpScreen extends StatefulWidget {
  const InstaHelpScreen({Key? key}) : super(key: key);

  @override
  State<InstaHelpScreen> createState() => _InstaHelpScreenState();
}

class _InstaHelpScreenState extends State<InstaHelpScreen>
    with TickerProviderStateMixin {
  late AnimationController _dispatchController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  String _selectedEmergency = 'Pipe Burst';
  Map<String, int> _selectedServices = {};
  int _footerSelectedIndex = 1;

  final List<Map<String, dynamic>> _emergencies = [
    {
      'icon': '🔧',
      'name': 'Pipe Burst',
      'selected': true,
      'rating': 4.8,
      'count': 1250,
      'price': 1299,
    },
    {
      'icon': '⚡',
      'name': 'Short Circuit',
      'selected': false,
      'rating': 4.6,
      'count': 892,
      'price': 899,
    },
    {
      'icon': '🔥',
      'name': 'Gas Leak',
      'selected': false,
      'rating': 4.9,
      'count': 445,
      'price': 1599,
    },
    {
      'icon': '💧',
      'name': 'Water Supply',
      'selected': false,
      'rating': 4.7,
      'count': 673,
      'price': 499,
    },
  ];

  int get _totalPrice {
    int total = 0;
    _selectedServices.forEach((service, count) {
      final price = _emergencies
          .firstWhere((e) => e['name'] == service)['price'] as int;
      total += price * count;
    });
    return total;
  }

  @override
  void initState() {
    super.initState();
    _dispatchController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dispatchController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _dispatchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.saffron.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on,
                color: AppTheme.saffron, size: 20),
          ),
        ),
        title: const Text(
          'Pune, MH',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.saffron.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications,
                  color: AppTheme.saffron, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dispatching Animation Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.95),
                    Colors.black.withOpacity(0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  // Animated Dispatching Circle
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer rotating ring
                        AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value * 6.28,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.saffron,
                                    width: 3,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Pulsing glow
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 200 +
                                  (_pulseAnimation.value * 30),
                              height: 200 +
                                  (_pulseAnimation.value * 30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.saffron
                                        .withOpacity(0.3 - _pulseAnimation.value * 0.3),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Center icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.saffron
                                .withOpacity(0.2),
                          ),
                          child: const Center(
                            child: Text(
                              '🎯',
                              style: TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'DISPATCHING',
                    style: TextStyle(
                      color: AppTheme.saffron,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pro Located!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00C853),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Found 12 online in your area...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Insta Help Header
                  Row(
                    children: [
                      const Text(
                        'Insta Help',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '⚡',
                        style: TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Emergency services dispatched instantly',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Promise Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.saffron,
                          AppTheme.saffronDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.saffron
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                                color: Colors.white
                                    .withOpacity(0.2),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.schedule,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'MAHA PROMISE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '46-Minute Guarantee',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Expert arrival or service is 50% off',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Emergency Selected
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Emergency Selected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            decoration:
                                TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Emergency Options Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final emergency = _emergencies[index];
                      final isSelected =
                          emergency['name'] ==
                              _selectedEmergency;
                      final quantity =
                          _selectedServices[
                                  emergency['name']]
                              ?? 0;
                      final price =
                          emergency['price'] as int;

                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.saffron
                                      .withOpacity(0.1)
                                  : Colors.grey.shade50,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.saffron
                                    : Colors.grey
                                        .shade300,
                                width:
                                    isSelected ? 2 : 1,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Text(
                                  emergency['icon']
                                      as String,
                                  style:
                                      const TextStyle(
                                    fontSize: 32,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  '₹${price}',
                                  style:
                                      TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color: AppTheme
                                        .saffron,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  emergency['name']
                                      as String,
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color: isSelected
                                        ? Colors
                                            .black
                                        : Colors
                                            .grey,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors
                                          .amber,
                                      size: 11,
                                    ),
                                    const SizedBox(
                                      width: 2,
                                    ),
                                    Text(
                                      '${emergency['rating']}',
                                      style:
                                          TextStyle(
                                        fontSize: 9,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color: Colors
                                            .grey
                                            .shade600,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    Text(
                                      '(${emergency['count']})',
                                      style:
                                          TextStyle(
                                        fontSize: 8,
                                        color: Colors
                                            .grey
                                            .shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration:
                                    const BoxDecoration(
                                  shape: BoxShape
                                      .circle,
                                  color: AppTheme
                                      .saffron,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme
                                          .saffron,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors
                                        .white,
                                    size: 13,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: quantity > 0
                                ? Container(
                                    decoration:
                                        BoxDecoration(
                                      color: AppTheme
                                          .saffron,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme
                                              .saffron
                                              .withOpacity(
                                                  0.3),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                          MainAxisSize
                                              .min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(
                                              () {
                                                if (quantity >
                                                    1) {
                                                  _selectedServices[emergency['name']] =
                                                      quantity -
                                                          1;
                                                } else {
                                                  _selectedServices.remove(
                                                      emergency[
                                                          'name']);
                                                }
                                              },
                                            );
                                          },
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration:
                                                BoxDecoration(
                                              color: AppTheme
                                                  .saffron
                                                  .withOpacity(
                                                      0.8),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          4),
                                            ),
                                            child:
                                                const Center(
                                              child: Icon(
                                                Icons
                                                    .remove,
                                                color: Colors
                                                    .white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment:
                                              Alignment
                                                  .center,
                                          child: Text(
                                            '$quantity',
                                            style:
                                                const TextStyle(
                                              color: Colors
                                                  .white,
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(
                                              () {
                                                _selectedServices[
                                                        emergency[
                                                            'name']]
                                                    = quantity +
                                                        1;
                                              },
                                            );
                                          },
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration:
                                                BoxDecoration(
                                              color: AppTheme
                                                  .saffron,
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          4),
                                            ),
                                            child:
                                                const Center(
                                              child: Icon(
                                                Icons.add,
                                                color: Colors
                                                    .white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedServices[
                                                emergency[
                                                    'name']]
                                            = 1;
                                      });
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration:
                                          BoxDecoration(
                                        color: AppTheme
                                            .saffron,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme
                                                .saffron
                                                .withOpacity(
                                                    0.3),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child:
                                          const Center(
                                        child: Icon(
                                          Icons.add,
                                          color: Colors
                                              .white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Checkout Section
                  if (_selectedServices.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._selectedServices.entries
                              .map((entry) {
                            final serviceName =
                                entry.key;
                            final quantity =
                                entry.value;
                            final price =
                                _emergencies
                                    .firstWhere((e) =>
                                        e['name'] ==
                                        serviceName)['price']
                                    as int;

                            return Padding(
                              padding: const EdgeInsets
                                  .only(bottom: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  Text(
                                    '$serviceName × $quantity',
                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                      color: Colors
                                          .grey,
                                    ),
                                  ),
                                  Text(
                                    '₹${price * quantity}',
                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: Colors
                                          .black,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                          Container(
                            height: 1,
                            color:
                                Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '₹${_totalPrice}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: AppTheme
                                      .saffron,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Dispatch Button
                  SizedBox(
                    width: double.infinity,
                    height: isSmall ? 50 : 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.saffron,
                            AppTheme.saffronDark,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.saffron
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(14),
                          onTap: _selectedServices
                                  .isEmpty
                              ? null
                              : () {},
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              const Icon(
                                Icons.phone,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                _selectedServices
                                        .isEmpty
                                    ? 'SELECT A SERVICE'
                                    : 'DISPATCH NOW • ₹${_totalPrice}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: isSmall
                                      ? 12
                                      : 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomFooter(
        selectedIndex: _footerSelectedIndex,
      ),
    );
  }
}
