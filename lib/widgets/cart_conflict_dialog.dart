import 'package:flutter/material.dart';
import '../services/cart_service.dart';

class _AppColors {
  static const brand = Color(0xFFFF9A4D);
  static const brandDeep = Color(0xFFF2762B);
  static const brandSoft = Color(0xFFFFF1E4);
  static const canvas = Color(0xFFFFF9F4);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFF0DFD0);
  static const ink = Color(0xFF2B1B10);
  static const inkSoft = Color(0xFF8A7361);
  static const warning = Color(0xFFF59E0B);
}

Future<bool> showCartConflictDialog(
  BuildContext context, {
  required String newServiceName,
  required String currentServiceName,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: _AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.shopping_cart_rounded, color: _AppColors.warning, size: 24),
                const SizedBox(width: 8),
                const Text('Cart Contains Different Service',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: _AppColors.ink)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your cart has:',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500, color: _AppColors.inkSoft)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(currentServiceName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.brandDeep)),
                ),
                const SizedBox(height: 12),
                Text('You want to add:',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500, color: _AppColors.inkSoft)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEF7EC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(newServiceName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981))),
                ),
                const SizedBox(height: 12),
                Text('Clear your cart and add this service instead?',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500, color: _AppColors.ink)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: _AppColors.inkSoft,
                ),
                child: const Text('Keep Cart',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.brandDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Clear & Add',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ) ??
      false;
}

void handleAddToCart(
  BuildContext context, {
  required CartService cartService,
  required CartItem newItem,
  required String newServiceName,
}) async {
  if (cartService.hasDifferentCategory(newItem.categoryId)) {
    final shouldClearAndAdd = await showCartConflictDialog(
      context,
      newServiceName: newServiceName,
      currentServiceName: cartService.items.first.serviceName,
    );

    if (shouldClearAndAdd) {
      cartService.replaceCart(newItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cart cleared. New service added.'),
          backgroundColor: _AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } else {
    cartService.addItem(newItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart'),
        backgroundColor: _AppColors.brand,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

const Color success = Color(0xFF10B981);
