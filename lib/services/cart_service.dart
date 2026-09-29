import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String id;
  final String serviceName;
  final String serviceId;
  final String categoryId;
  final String price;
  final String description;
  final String duration;
  final String serviceIcon;
  final String? imagePath;
  int quantity;
  DateTime? selectedDate;
  String? selectedTimeSlot;
  String? specialRequests;

  CartItem({
    required this.id,
    required this.serviceName,
    required this.serviceId,
    required this.categoryId,
    required this.price,
    required this.description,
    required this.duration,
    required this.serviceIcon,
    this.imagePath,
    this.quantity = 1,
    this.selectedDate,
    this.selectedTimeSlot,
    this.specialRequests,
  });

  double get totalPrice {
    final cleanPrice = price.replaceAll('₹', '').replaceAll(',', '');
    final priceValue = double.tryParse(cleanPrice) ?? 0;
    return priceValue * quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'serviceId': serviceId,
      'categoryId': categoryId,
      'price': price,
      'description': description,
      'duration': duration,
      'serviceIcon': serviceIcon,
      'imagePath': imagePath,
      'quantity': quantity,
      'selectedDate': selectedDate?.toIso8601String(),
      'selectedTimeSlot': selectedTimeSlot,
      'specialRequests': specialRequests,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceId: json['serviceId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      price: json['price'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      serviceIcon: json['serviceIcon'] ?? '',
      imagePath: json['imagePath'],
      quantity: json['quantity'] ?? 1,
      selectedDate: json['selectedDate'] != null ? DateTime.parse(json['selectedDate']) : null,
      selectedTimeSlot: json['selectedTimeSlot'],
      specialRequests: json['specialRequests'],
    );
  }
}

class CartService with ChangeNotifier {
  static final CartService _instance = CartService._internal();
  static const String _cartStorageKey = 'maha_cart_items';

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  final List<CartItem> _items = [];
  bool _isInitialized = false;

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  String? get firstServiceCategory {
    return _items.isNotEmpty ? _items.first.categoryId : null;
  }

  // ✅ Check if trying to add DIFFERENT SERVICE (by SERVICE NAME, not ID)
  bool hasDifferentServiceByName(String serviceName) {
    final isDifferent = _items.isNotEmpty && _items.first.serviceName != serviceName;
    debugPrint('🔍 hasDifferentServiceByName check:');
    debugPrint('   Cart items: ${_items.length}');
    if (_items.isNotEmpty) {
      debugPrint('   First item serviceName: ${_items.first.serviceName}');
      debugPrint('   New item serviceName: $serviceName');
      debugPrint('   Is different? $isDifferent');
    }
    return isDifferent;
  }

  bool hasDifferentService(String serviceId) {
    // Deprecated: Use hasDifferentServiceByName instead
    return false;
  }

  bool hasDifferentCategory(String categoryId) {
    // Deprecated: Use hasDifferentService instead (SERVICE-based enforcement, not category-based)
    return false;  // Always return false, check service instead
  }

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartStorageKey);

      // Always clear and reload - don't use _isInitialized flag
      _items.clear();

      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        for (var item in decoded) {
          _items.add(CartItem.fromJson(item));
        }
        debugPrint('✅ Cart loaded: ${_items.length} items');
      } else {
        debugPrint('✅ Cart empty: no saved items');
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading cart: $e');
      _isInitialized = true;
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartStorageKey, cartJson);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  // ✅ ENFORCES SINGLE CATEGORY ONLY - Changed from serviceId to categoryId
  Future<void> addItem(CartItem item) async {
    if (_items.isEmpty || _items.first.categoryId == item.categoryId) {
      final existingIndex = _items.indexWhere((i) => i.id == item.id);

      if (existingIndex >= 0) {
        _items[existingIndex].quantity += item.quantity;
      } else {
        _items.add(item);
      }
    } else {
      // Different category - replace entire cart
      _items.clear();
      _items.add(item);
    }
    await _saveCart();  // ✅ NOW AWAITED
    debugPrint('✅ Item added & saved: ${item.serviceName} (Category: ${item.categoryId})');
    notifyListeners();
  }

  Future<void> replaceCart(CartItem item) async {
    _items.clear();
    _items.add(item);
    await _saveCart();  // ✅ NOW AWAITED
    debugPrint('✅ Cart replaced with: ${item.serviceName} (Category: ${item.categoryId})');
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    final item = _items.firstWhere((i) => i.id == itemId);
    item.quantity = quantity.clamp(1, 10);
    _saveCart();
    notifyListeners();
  }

  void updateItemDetails(String itemId, {DateTime? date, String? timeSlot, String? requests}) {
    final item = _items.firstWhere((i) => i.id == itemId);
    if (date != null) item.selectedDate = date;
    if (timeSlot != null) item.selectedTimeSlot = timeSlot;
    if (requests != null) item.specialRequests = requests;
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }
}
