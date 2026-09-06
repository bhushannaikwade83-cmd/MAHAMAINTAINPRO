import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String serviceName;
  final String price;
  final String description;
  final String duration;
  final String serviceIcon;
  // Real photo for this service/category - a network URL (from the DB's
  // image_path) or a local asset path. Null falls back to serviceIcon.
  final String? imageUrl;
  int quantity;
  DateTime? selectedDate;
  String? selectedTimeSlot;
  String? specialRequests;

  CartItem({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.description,
    required this.duration,
    required this.serviceIcon,
    this.imageUrl,
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
}

class CartService with ChangeNotifier {
  static final CartService _instance = CartService._internal();

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    final item = _items.firstWhere((i) => i.id == itemId);
    item.quantity = quantity.clamp(1, 10);
    notifyListeners();
  }

  void updateItemDetails(String itemId, {DateTime? date, String? timeSlot, String? requests}) {
    final item = _items.firstWhere((i) => i.id == itemId);
    if (date != null) item.selectedDate = date;
    if (timeSlot != null) item.selectedTimeSlot = timeSlot;
    if (requests != null) item.specialRequests = requests;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
