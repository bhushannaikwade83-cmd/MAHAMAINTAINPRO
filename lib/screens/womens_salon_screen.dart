import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_footer.dart';

class WomensSalonScreen extends StatefulWidget {
  const WomensSalonScreen({Key? key}) : super(key: key);

  @override
  State<WomensSalonScreen> createState() => _WomensSalonScreenState();
}

class _WomensSalonScreenState extends State<WomensSalonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Map<String, int> _selectedServices = {};
  int _footerSelectedIndex = 1;

  final List<Map<String, dynamic>> _services = [
    {
      'icon': '✂️',
      'name': 'Hair Cut & Styling',
      'subtitle': '(Women)',
      'duration': '45-60 min',
      'rating': 4.9,
      'price': 399,
    },
    {
      'icon': '🧴',
      'name': 'Facial',
      'subtitle': '(Basic/D-Tan)',
      'duration': '60 min',
      'rating': 4.8,
      'price': 499,
    },
    {
      'icon': '💅',
      'name': 'Full Body Waxing',
      'subtitle': '(Women)',
      'duration': '45 min',
      'rating': 4.7,
      'price': 599,
    },
    {
      'icon': '💆‍♀️',
      'name': 'Head Massage',
      'subtitle': '(Oil Treatment)',
      'duration': '30 min',
      'rating': 4.9,
      'price': 299,
    },
    {
      'icon': '💄',
      'name': 'Makeup',
      'subtitle': '(Bridal/Party)',
      'duration': '60 min',
      'rating': 4.8,
      'price': 799,
    },
    {
      'icon': '🧖‍♀️',
      'name': 'Threading',
      'subtitle': '(Face/Eyebrows)',
      'duration': '20 min',
      'rating': 4.6,
      'price': 199,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _totalPrice {
    int total = 0;
    _selectedServices.forEach((service, count) {
      final price =
          _services.firstWhere((s) => s['name'] == service)['price'] as int;
      total += price * count;
    });
    return total;
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
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.saffron.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Women's Salon & Spa",
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'At-home beauty & wellness',
              style: TextStyle(
                fontSize: isSmall ? 10 : 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Services Grid
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      final quantity =
                          _selectedServices[service['name']] ?? 0;
                      final price = service['price'] as int;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                            ),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppTheme.saffron
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    service['icon'] as String,
                                    style:
                                        const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Service Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                service['name']
                                                    as String,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              if ((service['subtitle']
                                                      as String)
                                                  .isNotEmpty)
                                                Text(
                                                  service['subtitle']
                                                      as String,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors
                                                        .grey.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 60,
                                          child: quantity > 0
                                              ? Container(
                                                  decoration:
                                                      BoxDecoration(
                                                    color: AppTheme
                                                        .saffron,
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize
                                                            .min,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            if (quantity >
                                                                1) {
                                                              _selectedServices[
                                                                  service[
                                                                      'name']] =
                                                                  quantity -
                                                                      1;
                                                            } else {
                                                              _selectedServices
                                                                  .remove(
                                                                service[
                                                                    'name'],
                                                              );
                                                            }
                                                          });
                                                        },
                                                        child: Container(
                                                          width: 20,
                                                          height: 28,
                                                          alignment:
                                                              Alignment
                                                                  .center,
                                                          child:
                                                              const Text(
                                                            '−',
                                                            style:
                                                                TextStyle(
                                                              color: Colors
                                                                  .white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        width: 20,
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
                                                          setState(() {
                                                            _selectedServices[
                                                                service[
                                                                    'name']] =
                                                                quantity + 1;
                                                          });
                                                        },
                                                        child: Container(
                                                          width: 20,
                                                          height: 28,
                                                          alignment:
                                                              Alignment
                                                                  .center,
                                                          child:
                                                              const Text(
                                                            '+',
                                                            style:
                                                                TextStyle(
                                                              color: Colors
                                                                  .white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
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
                                                          service[
                                                              'name']] =
                                                          1;
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration:
                                                        BoxDecoration(
                                                      color: Colors
                                                          .grey.shade100,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(8),
                                                      border: Border.all(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                      ),
                                                    ),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.add,
                                                        color: Colors
                                                            .grey,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.schedule,
                                            size: 13,
                                            color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          service['duration']
                                              as String,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star,
                                            size: 12,
                                            color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${service['rating']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '₹$price',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.saffron,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Order Summary
                  if (_selectedServices.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._selectedServices.entries.map((entry) {
                            final serviceName = entry.key;
                            final quantity = entry.value;
                            final price = _services
                                .firstWhere(
                                    (s) => s['name'] == serviceName)['price']
                                as int;

                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$serviceName × $quantity',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '₹${price * quantity}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                          Container(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '₹${_totalPrice}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.saffron,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Book Button
                  SizedBox(
                    width: double.infinity,
                    height: isSmall ? 48 : 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.saffron,
                            AppTheme.saffronDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.saffron.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _selectedServices.isEmpty ? null : () {},
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedServices.isEmpty
                                    ? 'SELECT A SERVICE'
                                    : 'BOOK NOW • ₹${_totalPrice}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmall ? 12 : 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomFooter(
        selectedIndex: _footerSelectedIndex,
        onNavItemTap: (index) {},
      ),
    );
  }
}
