# Service Marketplace Cart API Documentation

## Base URL
```
/api/v1
```

## Authentication
All endpoints require JWT authentication via `Authorization: Bearer <token>` header.

---

## Cart Endpoints

### GET /cart
**Fetch complete cart for authenticated user**

**Request:**
```
GET /api/v1/cart
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "cart_id": "CART_9773609077_001",
  "user_id": "9773609077",
  "item_count": 1,
  "items": [{
    "id": 1,
    "service_id": 1,
    "service_name": "AC Service",
    "package_name": "Premium",
    "quantity": 1,
    "unit_price": 799.00,
    "addons": [{
      "addon_id": 1,
      "addon_name": "Gas Refill",
      "addon_price": 499.00
    }]
  }],
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

### POST /cart/add-item
**Add service to cart**

**Request:**
```json
{
  "service_id": 1,
  "package_id": 3,
  "quantity": 1,
  "selected_addons": [1, 2],
  "options": null,
  "provider_id": null
}
```

**Response:**
Same as GET /cart

---

### DELETE /cart/remove-item
**Remove item from cart**

**Query Params:**
- `id`: Cart item ID

**Response:**
Same as GET /cart

---

### POST /cart/clear
**Empty entire cart**

**Request:**
```json
{
  "cart_id": "CART_9773609077_001"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Cart cleared"
}
```

---

### POST /cart/validate
**Validate cart before checkout**

**Request:**
```json
{
  "cart_id": "CART_9773609077_001",
  "service_location_id": 15,
  "scheduled_date": "2026-09-30",
  "time_slot_id": 1
}
```

**Response:**
```json
{
  "success": true,
  "valid": true,
  "issues": [],
  "pricing": {...},
  "message": "Cart is valid"
}
```

**Issues Types:**
- `EMPTY_CART`
- `LOCATION_REQUIRED`
- `DATE_REQUIRED`
- `SLOT_REQUIRED`
- `SLOT_UNAVAILABLE`
- `SLOT_FULLY_BOOKED`
- `MINIMUM_VALUE_NOT_MET`
- `PRICE_CHANGED`

---

## Coupon Endpoints

### POST /coupon/validate
**Validate coupon eligibility**

**Request:**
```json
{
  "coupon_code": "SAVE200",
  "cart_value": 1500.00
}
```

**Response:**
```json
{
  "valid": true,
  "code": "SAVE200",
  "discount_type": "fixed",
  "discount_value": 200.00,
  "discount_amount": 200.00,
  "message": "Coupon applied successfully"
}
```

---

## Checkout Endpoints (Phase 3 - Complete)

### POST /checkout/init
Initialize checkout session, lock prices, reserve slot
- Request: `cart_id`, `service_location_id`, `scheduled_date`, `time_slot_id`
- Response: `checkout_id`, locked `pricing`, 15-min expiry
- See [CHECKOUT_API.md](CHECKOUT_API.md) for details

### POST /checkout/payment-intent
Create Razorpay payment order
- Request: `checkout_id`
- Response: `razorpay_order_id`, `key`, amount
- See [CHECKOUT_API.md](CHECKOUT_API.md) for details

### POST /checkout/verify-payment
Verify payment and create booking (SERVER-TO-SERVER ONLY)
- Request: `checkout_id`, `razorpay_payment_id`, `razorpay_signature`
- Response: `booking_id`, `order_id`, confirmed status
- See [CHECKOUT_API.md](CHECKOUT_API.md) for details

### GET /checkout/status
Get checkout and booking status
- Query: `checkout_id`
- Response: Full checkout state with booking details
- See [CHECKOUT_API.md](CHECKOUT_API.md) for details

### POST /checkout/cancel
Cancel checkout and release slot reservation
- Request: `checkout_id`
- Response: Success message
- Only works before payment verified

---

## Service Endpoints

### GET /services/:id/details
Get service details with packages and add-ons

### GET /slots/available
Get available time slots for date

### GET /locations/serviceable
Check if service is available in location

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "message": "Error description",
  "error": "Exception message (dev only)"
}
```

**HTTP Status Codes:**
- `200` - Success
- `400` - Bad request / Validation error
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not found
- `405` - Method not allowed
- `500` - Server error

---

## Database Tables Used

- `carts` - Cart storage
- `cart_items` - Items in cart
- `cart_item_addons` - Add-ons per item
- `services` - Service definitions
- `service_packages` - Service variants
- `service_addons` - Add-on options
- `coupons` - Discount codes
- `service_time_slots` - Available time slots
- `addresses` - Service locations

---

## Key Features

✅ Server-side pricing (client cannot manipulate)
✅ Coupon validation and application
✅ Real-time slot availability checking
✅ Service location serviceability checks
✅ Price snapshots for audit trail
✅ Transaction-safe checkout process
✅ Comprehensive validation
✅ Error handling with clear messages

---

## Implementation Status

- [x] Phase 1: Database Schema
- [x] Phase 2: Backend Services (CartService, PricingService)
- [x] Phase 2: Cart APIs (GET, POST, DELETE)
- [x] Phase 2: Coupon API
- [ ] Phase 3: Checkout Flow
- [ ] Phase 4: Slot Management
- [ ] Phase 5: Frontend Cart Screen
- [ ] Phase 6: Frontend Checkout
- [ ] Phase 7: Testing

---

**Last Updated:** September 29, 2026  
**API Version:** 1.0  
**Status:** Phase 2 Complete, Phase 3 In Progress
