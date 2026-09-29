import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';

/// Full detail view for a single service: name, image, description,
/// price, what's included/excluded, estimated time, warranty, FAQ and
/// related services from the same category. All content comes from the
/// live API response (get-services.php) - nothing here is fabricated
/// (no fake review counts, no simulated live tracking).
class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final String categoryName;
  final String categoryEmoji;
  final List<Map<String, dynamic>> relatedServices;
  final List<Map<String, dynamic>> faqs;

  const ServiceDetailScreen({
    required this.service,
    required this.categoryName,
    required this.categoryEmoji,
    this.relatedServices = const [],
    this.faqs = const [],
    Key? key,
  }) : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int _quantity = 1;

  int get _priceValue => (widget.service['price'] as num?)?.toInt() ?? 0;

  List<String> _splitLines(dynamic value) {
    if (value == null) return [];
    return value
        .toString()
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _addToCartAndCheckout() async {
    final service = widget.service;
    final cartService = CartService();

    // ✅ CRITICAL: Load cart from storage first before checking category
    await cartService.loadCart();

    final serviceId = '${service['id']}';
    final serviceName = service['name'] ?? 'Service';
    final serviceCategoryId = '${service['category_id'] ?? ''}';

    final cartItem = CartItem(
      id: serviceId,
      serviceName: serviceName,
      serviceId: serviceId,
      categoryId: serviceCategoryId,
      price: '₹${service['price'] ?? 0}',
      description: service['description'] ?? '',
      duration: service['duration'] ?? '',
      serviceIcon: service['emoji'] ?? widget.categoryEmoji,
      imagePath: service['image_path'],
      quantity: _quantity,
    );

    // Check if trying to add DIFFERENT SERVICE (by name, allows same service from diff categories)
    if (cartService.hasDifferentServiceByName(serviceName)) {
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
                await cartService.replaceCart(cartItem);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              child: const Text('Replace Cart'),
            ),
          ],
        ),
      );
    } else {
      // Same category - just add
      await cartService.addItem(cartItem);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final included = _splitLines(service['whats_included']);
    final notIncluded = _splitLines(service['whats_not_included']);
    final warranty = service['warranty_text'] as String?;
    final imagePath = service['image_path'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          service['name'] ?? 'Service',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service image
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey.shade100,
              child: imagePath != null && imagePath.isNotEmpty
                  ? Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      errorBuilder: (c, e, st) => Center(
                        child: Text(widget.categoryEmoji, style: const TextStyle(fontSize: 64)),
                      ),
                    )
                  : Center(child: Text(widget.categoryEmoji, style: const TextStyle(fontSize: 64))),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service['name'] ?? 'Service',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '₹$_priceValue',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.saffron),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (service['duration'] != null && service['duration'].toString().isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(service['duration'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    service['description'] ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
                  ),

                  if (warranty != null && warranty.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4EDDA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF28A745)),
                          const SizedBox(width: 6),
                          Text(
                            warranty,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF28A745)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (included.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text("What's included", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...included.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Color(0xFF28A745)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )),
                  ],

                  if (notIncluded.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text("What's not included", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...notIncluded.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )),
                  ],

                  const SizedBox(height: 20),

                  // Quantity selector
                  const Text('Quantity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.saffron, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _quantity = (_quantity - 1).clamp(1, 10)),
                          tooltip: 'Decrease quantity',
                          icon: Icon(Icons.remove, color: AppTheme.saffron),
                        ),
                        Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: () => setState(() => _quantity = (_quantity + 1).clamp(1, 10)),
                          tooltip: 'Increase quantity',
                          icon: Icon(Icons.add, color: AppTheme.saffron),
                        ),
                      ],
                    ),
                  ),

                  if (widget.faqs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Frequently Asked Questions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...widget.faqs.map((faq) => ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            faq['q']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                faq['a']?.toString() ?? '',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        )),
                  ],

                  if (widget.relatedServices.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Related services', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...widget.relatedServices.map((related) {
                      final relPrice = (related['price'] as num?)?.toInt();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServiceDetailScreen(
                                  service: related,
                                  categoryName: widget.categoryName,
                                  categoryEmoji: widget.categoryEmoji,
                                  relatedServices: widget.relatedServices,
                                  faqs: widget.faqs,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    related['name'] ?? '',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (relPrice != null)
                                  Text(
                                    '₹$relPrice',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.saffron),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '₹${_priceValue * _quantity}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.saffron),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addToCartAndCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
