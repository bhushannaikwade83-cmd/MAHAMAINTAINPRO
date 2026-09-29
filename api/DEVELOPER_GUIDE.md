# Cart System Developer Guide

## Quick Reference for Using Cart Services

### CartService Usage

```php
<?php
require_once 'config.php';
require_once 'services/cart_service.php';

$cart = new CartService($pdo, $phone_number);

// Initialize/get cart
$cart_id = $cart->initCart($service_location_id);
$cart->setCartId($cart_id);

// Add item
$cart->addItem(
    $service_id,        // Service ID
    $package_id,        // Package/variant ID (optional)
    $quantity,          // 1-10
    [1, 2, 3],         // Add-on IDs array
    ['option' => 'value'], // Custom options (optional)
    $provider_id        // Provider (optional)
);

// Get full cart
$cart_data = $cart->getCart();

// Update item
$cart->updateItem(
    $cart_item_id,
    $quantity,          // New quantity
    [1, 2],            // New add-ons
    null,              // Keep options
    $provider_id       // Update provider
);

// Remove item
$cart->removeItem($cart_item_id);

// Recalculate pricing
$cart->recalculatePricing();

// Clear cart
$cart->clearCart();
?>
```

---

### PricingService Usage

```php
<?php
require_once 'config.php';
require_once 'services/pricing_service.php';

$pricing = new PricingService($pdo);

// Calculate complete pricing
$pricing_details = $pricing->calculateCartPricing(
    $cart_id,
    $service_location_id,
    $coupon_id          // Optional
);

// Result includes:
// {
//   "items_subtotal": 1298.00,
//   "addons_total": 499.00,
//   "service_fee": 0.00,
//   "travel_fee": 50.00,
//   "tax_rate": 18.00,
//   "tax_amount": 211.00,
//   "discount_amount": 200.00,
//   "total": 1359.00,
//   "items": [...]
// }

// Validate coupon
$coupon_result = $pricing->validateAndApplyCoupon($coupon_id, $cart_value);
// Returns: { "valid": bool, "discount_amount": ..., "message": "..." }

// Detect price changes
$changes = $pricing->detectPriceChanges($old_pricing, $new_pricing);

// Format for display
$display_pricing = $pricing->formatPricingForDisplay($pricing_details);
// Returns: { "subtotal": "₹1,298.00", "total": "₹1,359.00", ... }
?>
```

---

## API Response Examples

### GET /api/v1/cart

```json
{
  "success": true,
  "cart_id": "CART_9773609077_001",
  "item_count": 1,
  "items": [
    {
      "id": 1,
      "service_id": 1,
      "service_name": "AC Service",
      "package_name": "Premium",
      "quantity": 1,
      "unit_price": 799.00,
      "item_subtotal": 1298.00,
      "addons": [
        {
          "addon_id": 1,
          "addon_name": "Gas Refill",
          "addon_price": 499.00
        }
      ]
    }
  ],
  "pricing": {
    "items_subtotal": 1298.00,
    "addons_total": 499.00,
    "service_fee": 0.00,
    "travel_fee": 50.00,
    "tax_rate": 18.00,
    "tax_amount": 211.00,
    "discount_amount": 0.00,
    "total": 1559.00,
    "currency": "INR"
  },
  "can_checkout": true
}
```

---

## Database Relationships

```
carts (1)
  ├── cart_items (many)
  │   ├── service (1)
  │   ├── package (1)
  │   └── cart_item_addons (many)
  │       └── service_addon (1)
  ├── coupons (1)
  ├── addresses (1) [service_location]
  └── vendors (1) [provider]
```

---

## Key Design Patterns

### 1. Always Recalculate on Changes
```php
// After modifying cart
$cart->addItem(...);
$cart->recalculatePricing();  // Must call this!
```

### 2. Price Snapshots for Audit
```php
// Pricing is automatically saved in cart_pricing table
// for audit trail and price change detection
```

### 3. Validation Before Checkout
```php
// In checkout flow
$result = $pricing->validateAndApplyCoupon($coupon_id, $subtotal);
if (!$result['valid']) {
    // Handle error
}
```

### 4. Server-Side Pricing (CRITICAL)
```php
// NEVER trust client-submitted prices
// ALWAYS calculate on backend
$pricing = $pricing_service->calculateCartPricing($cart_id);
// Use this pricing for booking, not client's prices
```

---

## Error Handling

```php
try {
    $cart->addItem($service_id, $package_id, $quantity, $addons);
} catch (Exception $e) {
    // Log error
    error_log($e->getMessage());
    
    // Return proper error response
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Error adding item to cart',
        'error' => $e->getMessage()
    ]);
}
```

---

## Common Workflows

### Workflow 1: Add Service to Cart

```php
$cart = new CartService($pdo, $phone_number);
$cart_id = $cart->initCart();
$cart->setCartId($cart_id);

$cart->addItem(
    service_id: 1,
    package_id: 3,
    quantity: 1,
    selected_addons: [1, 2],
    provider_id: null
);

$cart_data = $cart->getCart();
// Return cart_data to client
```

### Workflow 2: Apply Coupon

```php
$pricing = new PricingService($pdo);

$result = $pricing->validateAndApplyCoupon($coupon_id, $cart_value);

if ($result['valid']) {
    // Update cart with coupon
    $stmt = $pdo->prepare("UPDATE carts SET coupon_id = ? WHERE cart_id = ?");
    $stmt->execute([$coupon_id, $cart_id]);
    
    // Recalculate
    $cart->recalculatePricing();
}
```

### Workflow 3: Complete Checkout (Phase 3)

```php
$checkout_service = new CheckoutService($pdo, $user_id);
$pricing_service = new PricingService($pdo);

// 1. Validate cart
$validation = $this->validateCart($cart_id);
if (!$validation['valid']) {
    return $validation['issues'];
}

// 2. Calculate final pricing
$pricing = $pricing_service->calculateCartPricing($cart_id, $service_location_id);

// 3. Initialize checkout (lock prices, reserve slot)
$checkout = $checkout_service->initCheckout(
    $cart_id,
    $service_location_id,
    '2026-09-30',  // scheduled_date
    $time_slot_id,
    $pricing
);
// Returns: checkout_id, locked pricing, 15-min expiry

// 4. Create Razorpay payment order
$payment = $checkout_service->createPaymentIntent(
    $checkout['checkout_id'],
    $checkout['pricing']['total'],
    RAZORPAY_KEY_ID,
    RAZORPAY_KEY_SECRET
);
// Returns: razorpay_order_id, key for frontend

// 5. Show Razorpay form to user
// Frontend handles payment with razorpay_order_id
// User pays and gets razorpay_response

// 6. Verify payment (server-to-server only!)
$booking = $checkout_service->verifyAndCreateBooking(
    $checkout['checkout_id'],
    $razorpay_response['razorpay_payment_id'],
    $razorpay_response['razorpay_signature'],
    RAZORPAY_KEY_ID,
    RAZORPAY_KEY_SECRET
);
// Returns: booking_id, order_id, confirmed status

// 7. Get booking details
$status = $checkout_service->getCheckoutStatus($checkout['checkout_id']);
```

---

## Database Queries

### Get Cart Total
```sql
SELECT SUM(ci.item_subtotal) as subtotal
FROM cart_items ci
WHERE ci.cart_id = ?
```

### Get Cart with Items and Addons
```sql
SELECT ci.*, 
       s.name as service_name,
       sp.name as package_name,
       GROUP_CONCAT(cia.addon_name) as addon_names
FROM cart_items ci
JOIN services s ON ci.service_id = s.id
LEFT JOIN service_packages sp ON ci.package_id = sp.id
LEFT JOIN cart_item_addons cia ON ci.id = cia.cart_item_id
WHERE ci.cart_id = ?
GROUP BY ci.id
```

### Check Slot Availability
```sql
SELECT is_available, booked_count, total_capacity
FROM time_slot_availability
WHERE slot_id = ? AND service_date = ?
```

---

## Testing Checklist

- [ ] Add item with package to cart
- [ ] Add item with add-ons to cart
- [ ] Update item quantity
- [ ] Remove item from cart
- [ ] Apply valid coupon
- [ ] Try invalid coupon
- [ ] Calculate pricing with tax
- [ ] Detect price changes
- [ ] Clear cart
- [ ] Validate cart before checkout
- [ ] Cart persists after app restart (server-side)
- [ ] Concurrent user cart isolation

---

**Last Updated:** September 29, 2026  
**For Questions:** Check API_DOCUMENTATION.md or database/migrations/README.md
