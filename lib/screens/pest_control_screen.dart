import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_footer.dart';

class PestControlScreen extends StatefulWidget {
  const PestControlScreen({Key? key}) : super(key: key);

  @override
  State<PestControlScreen> createState() => _PestControlScreenState();
}

class _PestControlScreenState extends State<PestControlScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Map<String, int> _selectedServices = {};
  int _footerSelectedIndex = 1;

  final List<Map<String, dynamic>> _services = [
    {'icon': '🐜', 'name': 'General Pest Control (1BHK)', 'duration': '1-2 hrs', 'rating': 4.7, 'price': 799},
    {'icon': '🐜', 'name': 'General Pest Control (2BHK)', 'duration': '1.5-2 hrs', 'rating': 4.7, 'price': 999},
    {'icon': '🐜', 'name': 'General Pest Control (3BHK)', 'duration': '2-3 hrs', 'rating': 4.8, 'price': 1299},
    {'icon': '🦟', 'name': 'Mosquito Control Treatment', 'duration': '1-2 hrs', 'rating': 4.6, 'price': 699},
    {'icon': '🕷️', 'name': 'Termite Treatment (1BHK)', 'duration': '2-3 hrs', 'rating': 4.8, 'price': 1499},
    {'icon': '🪳', 'name': 'Cockroach & Rodent Control', 'duration': '1.5-2 hrs', 'rating': 4.9, 'price': 899},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
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
      final price = _services.firstWhere((s) => s['name'] == service)['price'] as int;
      total += price * count;
    });
    return total;
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final quantity = _selectedServices[service['name']] ?? 0;
    final price = service['price'] as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: AppTheme.saffron.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(service['icon'] as String, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(service['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      SizedBox(
                        width: 60,
                        child: quantity > 0
                            ? Container(
                                decoration: BoxDecoration(color: AppTheme.saffron, borderRadius: BorderRadius.circular(8)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      if (quantity > 1) {
                                        _selectedServices[service['name']] = quantity - 1;
                                      } else {
                                        _selectedServices.remove(service['name']);
                                      }
                                    }),
                                    child: SizedBox(width: 20, height: 28, child: const Center(child: Text('−', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)))),
                                  ),
                                  SizedBox(width: 20, child: Center(child: Text('$quantity', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
                                  GestureDetector(
                                    onTap: () => setState(() => _selectedServices[service['name']] = quantity + 1),
                                    child: SizedBox(width: 20, height: 28, child: const Center(child: Text('+', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)))),
                                  ),
                                ]),
                              )
                            : GestureDetector(
                                onTap: () => setState(() => _selectedServices[service['name']] = 1),
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                                  child: const Center(child: Icon(Icons.add, color: Colors.grey, size: 18)),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(service['duration'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('${service['rating']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('₹$price', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.saffron)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.saffron.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.arrow_back, color: Colors.black, size: 20)),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Pest Control", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          Text('Safe, effective & certified treatments', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w400)),
        ]),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._services.map((service) => _buildServiceCard(service)).toList(),
              if (_selectedServices.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Order Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 10),
                    ..._selectedServices.entries.map((entry) {
                      final price = _services.firstWhere((s) => s['name'] == entry.key)['price'] as int;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('${entry.key} × ${entry.value}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('₹${price * entry.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                        ]),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    Container(height: 1, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text('₹${_totalPrice}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.saffron)),
                    ]),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.saffron, AppTheme.saffronDark]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppTheme.saffron.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                  child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(12), onTap: _selectedServices.isEmpty ? null : () {}, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(_selectedServices.isEmpty ? 'SELECT A SERVICE' : 'BOOK NOW • ₹${_totalPrice}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3)),
                  ]))),
                ),
              ),
              const SizedBox(height: 80),
            ],
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
