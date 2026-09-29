import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../config/app_theme.dart';
import '../data/service_catalog.dart';
import '../utils/constants.dart';
import 'schedule_service_screen.dart';
import 'service_detail_screen.dart';
import 'cart_screen.dart';

class ServiceCategoryScreen extends StatefulWidget {
  final String categoryName;
  final String categoryEmoji;
  final String? categoryIconPath;
  final String? categoryImagePath;
  final String description;
  final String categoryId;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> faqs;

  const ServiceCategoryScreen({
    required this.categoryName,
    required this.categoryEmoji,
    this.categoryIconPath,
    this.categoryImagePath,
    required this.description,
    required this.categoryId,
    required this.services,
    this.faqs = const [],
    Key? key,
  }) : super(key: key);

  @override
  State<ServiceCategoryScreen> createState() => _ServiceCategoryScreenState();
}

class _ServiceCategoryScreenState extends State<ServiceCategoryScreen> {
  late List<Map<String, dynamic>> _services;

  @override
  void initState() {
    super.initState();
    _loadServicesWithCartStatus();
  }

  Future<void> _loadServicesWithCartStatus() async {
    final cartService = CartService();
    await cartService.loadCart();

    setState(() {
      _services = widget.services.map((s) {
        final serviceId = '${s['id']}';
        final cartItem = cartService.items.firstWhere(
          (item) => item.serviceId == serviceId,
          orElse: () => CartItem(
            id: '', serviceName: '', serviceId: '', categoryId: '',
            price: '', description: '', duration: '', serviceIcon: '',
            quantity: 0,
          ),
        );

        final quantityInCart = cartItem.quantity;
        final isInCart = quantityInCart > 0;

        return <String, dynamic>{
          ...s,
          'quantity': quantityInCart,  // Show actual quantity from cart
          'isInCart': isInCart,
        };
      }).toList();
    });
  }

  int get totalPrice => _services.fold(0, (sum, item) => sum + (((item['price'] as int?) ?? 0) * (item['quantity'] as int)));
  int get totalServices => _services.fold(0, (sum, item) => sum + (item['quantity'] as int));

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

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
                colors: [AppTheme.saffron, AppTheme.saffronDark],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + (isSmall ? 8 : 10),
              left: 0,
              right: 0,
              bottom: isSmall ? 12 : 16,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button and Logo Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.arrow_back, size: isSmall ? 20 : 24, color: Colors.white),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: isSmall ? 34 : 40,
                          height: isSmall ? 34 : 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 10 : 12),
                  // Title with icon/emoji and badge if new
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.categoryIconPath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            widget.categoryIconPath!,
                            width: isSmall ? 30 : 36,
                            height: isSmall ? 30 : 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: isSmall ? 8 : 10),
                      ],
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: widget.categoryName,
                                style: TextStyle(
                                  fontSize: isSmall ? 22 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (widget.categoryIconPath == null)
                                TextSpan(
                                  text: ' ${widget.categoryEmoji}',
                                  style: TextStyle(fontSize: isSmall ? 22 : 26),
                                ),
                              if (widget.categoryName.contains('New') || widget.description.contains('New'))
                                TextSpan(
                                  text: '\n◆ New',
                                  style: TextStyle(
                                    fontSize: isSmall ? 10 : 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 6 : 8),
                  Text(
                    widget.description,
                    style: TextStyle(fontSize: isSmall ? 12 : 13, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ),

          // Services List
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  _services.length,
                  (index) => _buildServiceCard(index),
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          if (totalServices > 0)
            Container(
              padding: EdgeInsets.only(
                left: isSmall ? 12 : 16,
                right: isSmall ? 12 : 16,
                bottom: MediaQuery.of(context).padding.bottom + (isSmall ? 10 : 16),
                top: isSmall ? 10 : 16,
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmall ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalServices ${totalServices == 1 ? 'Service' : 'Services'} Selected',
                              style: TextStyle(fontSize: isSmall ? 11 : 12, color: Colors.grey.shade600),
                            ),
                            SizedBox(height: isSmall ? 3 : 4),
                            Text(
                              '₹$totalPrice',
                              style: TextStyle(
                                fontSize: isSmall ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmall ? 10 : 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CartScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.saffron,
                        padding: EdgeInsets.symmetric(vertical: isSmall ? 12 : 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'View Cart',
                        style: TextStyle(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;
    final service = _services[index];
    final isSelected = service['quantity'] > 0;

    return GestureDetector(
      onTap: () {
        final related = _services.where((s) => s['id'] != service['id']).take(3).toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(
              service: service,
              categoryName: widget.categoryName,
              categoryEmoji: widget.categoryEmoji,
              relatedServices: related,
              faqs: widget.faqs,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isSmall ? 8 : 12),
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: isSmall ? 12 : 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.saffron.withOpacity(0.05) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.saffron : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Builder(builder: (context) {
                final imagePath = service['image_path'] as String?;
                if (imagePath != null && imagePath.isNotEmpty) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      cacheWidth: 100,
                      cacheHeight: 100,
                      errorBuilder: (c,e,st) => Center(child: Text(service['emoji'] ?? '🔧', style: const TextStyle(fontSize: 24))),
                    ),
                  );
                }
                final iconPath = getServiceIcon(widget.categoryName, service['name'] ?? '');
                if (iconPath != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(iconPath, fit: BoxFit.cover),
                  );
                }
                return Center(
                  child: Text(service['emoji'] ?? '🔧', style: const TextStyle(fontSize: 24)),
                );
              }),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service['name'] ?? 'Service',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (service['isInCart'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Added',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (service['duration'] != null)
                          Text(
                            '⏱️ ${service['duration']}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        if (service['rating'] != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            '⭐ ${service['rating']}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service['price'] != null ? '₹${service['price']}' : 'Price on request',
                    style: TextStyle(
                      fontSize: service['price'] != null ? 15 : 12,
                      fontWeight: FontWeight.bold,
                      color: service['price'] != null ? AppTheme.saffron : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (service['quantity'] > 0) service['quantity']--;
                      });
                    },
                    child: Text(
                      '−',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.saffron,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${service['quantity']}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final cartService = CartService();

                      // ✅ CRITICAL: Load cart from storage first before checking category
                      await cartService.loadCart();
                      debugPrint('📦 SERVICE CATEGORY SCREEN - Adding service');
                      debugPrint('   Service: ${service['name']}');

                      final serviceCategoryId = widget.categoryId;
                      debugPrint('   Service category ID: $serviceCategoryId');

                      // Check if service is from different category
                      if (cartService.hasDifferentCategory(serviceCategoryId)) {
                        // Show conflict dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Different Category'),
                            content: const Text('Your cart has items from a different category.\n\nWould you like to replace them with this service?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  setState(() => service['quantity']++);

                                  // Replace entire cart with this service
                                  await cartService.replaceCart(CartItem(
                                    id: '${service['id']}',
                                    serviceName: service['name'] ?? 'Service',
                                    serviceId: '${service['id']}',
                                    categoryId: serviceCategoryId,
                                    price: '₹${service['price'] ?? 0}',
                                    description: service['description'] ?? '',
                                    duration: service['duration'] ?? '',
                                    serviceIcon: service['emoji'] ?? '✨',
                                    imagePath: widget.categoryImagePath,
                                    quantity: 1,
                                  ));
                                },
                                child: const Text('Replace Cart'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Same category - just add
                        setState(() => service['quantity']++);
                        await cartService.addItem(CartItem(
                          id: '${service['id']}',
                          serviceName: service['name'] ?? 'Service',
                          serviceId: '${service['id']}',
                          categoryId: serviceCategoryId,
                          price: '₹${service['price'] ?? 0}',
                          description: service['description'] ?? '',
                          duration: service['duration'] ?? '',
                          serviceIcon: service['emoji'] ?? '✨',
                          imagePath: widget.categoryImagePath,
                          quantity: 1,
                        ));
                      }
                    },
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.saffron,
                        fontWeight: FontWeight.bold,
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
