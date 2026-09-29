# Phase 3: Checkout Flow API Documentation

## Overview

Complete checkout flow with Razorpay integration:
1. Initialize checkout (lock prices, reserve slot)
2. Create payment order (Razorpay)
3. Verify payment & create booking
4. Check status and cancel if needed

All endpoints require JWT authentication.

---

## Endpoints

### 1. POST /api/v1/checkout/init
**Initialize checkout session**

Validates cart, locks prices, and reserves time slot for 15 minutes.

**Request:**
```json
{
  "cart_id": "CART_9773609077_001",
  "service_location_id": 15,
  "scheduled_date": "2026-09-30",
  "time_slot_id": 5
}
```

**Response (200):**
```json
{
  "success": true,
  "checkout_id": "CHECKOUT_9773609077_1727000000",
  "cart_id": "CART_9773609077_001",
  "pricing": {
    "items_subtotal": 1298.00,
    "addons_total": 499.00,
    "service_fee": 0.00,
    "travel_fee": 50.00,
    "tax_amount": 211.00,
    "total": 1359.00
  },
  "expires_in_minutes": 15
}
```

**Errors:**
- `400` - Missing fields, invalid date, slot unavailable
- `403` - Cart belongs to another user

---

### 2. POST /api/v1/checkout/payment-intent
**Create Razorpay payment order**

Creates a Razorpay order for the checkout amount.

**Request:**
```json
{
  "checkout_id": "CHECKOUT_9773609077_1727000000"
}
```

**Response (200):**
```json
{
  "success": true,
  "checkout_id": "CHECKOUT_9773609077_1727000000",
  "razorpay_order_id": "order_9Aqbb3N1ORweVi",
  "amount": 1359.00,
  "currency": "INR",
  "key": "rzp_live_xxxxxxxxxxxxx"
}
```

**Next Steps:**
Use `razorpay_order_id` and `key` to show Razorpay checkout form to user.

---

### 3. POST /api/v1/checkout/verify-payment
**Verify payment and create booking**

**CRITICAL:** This endpoint must be called SERVER-TO-SERVER. Never call from client.

**Request:**
```json
{
  "checkout_id": "CHECKOUT_9773609077_1727000000",
  "razorpay_payment_id": "pay_9Aqbb3N1ORweVi",
  "razorpay_signature": "9ef4dffbfd84f1318f6739a3ce19f9d85851857ae648f114332d8401e0949a3d"
}
```

**Razorpay Response Handling:**

On client, after payment success:
```javascript
// Client receives razorpay_response with:
// - razorpay_order_id
// - razorpay_payment_id
// - razorpay_signature

// Send to backend for verification
fetch('/api/v1/checkout/verify-payment', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer ' + jwt_token,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    checkout_id: checkout_id,
    razorpay_payment_id: razorpay_payment_id,
    razorpay_signature: razorpay_signature
  })
})
```

**Response (200):**
```json
{
  "success": true,
  "booking_id": "BOOKING_9773609077_1727000000",
  "order_id": "ORDER_9773609077_1727000000",
  "payment_id": "pay_9Aqbb3N1ORweVi",
  "status": "confirmed"
}
```

**What Happens:**
1. Signature verified against Razorpay secret
2. Booking created in database
3. Order created with items and pricing
4. Cart marked as checked out
5. User notified (via email/SMS)

**Errors:**
- `400` - Invalid signature, expired session
- `403` - Unauthorized

---

### 4. GET /api/v1/checkout/status
**Get checkout and booking status**

**Query:**
```
GET /api/v1/checkout/status?checkout_id=CHECKOUT_9773609077_1727000000
```

**Response (200):**
```json
{
  "success": true,
  "checkout_id": "CHECKOUT_9773609077_1727000000",
  "status": "payment_verified",
  "cart_id": "CART_9773609077_001",
  "scheduled_date": "2026-09-30",
  "payment_amount": 1359.00,
  "created_at": "2026-09-29 14:00:00",
  "expires_at": "2026-09-29 14:15:00",
  "is_expired": false,
  "booking_id": "BOOKING_9773609077_1727000000",
  "booking_status": "confirmed",
  "payment_id": "pay_9Aqbb3N1ORweVi"
}
```

**Statuses:**
- `initiated` - Checkout started, awaiting payment
- `payment_initiated` - Razorpay order created
- `payment_verified` - Payment successful, booking created
- `cancelled` - Checkout cancelled

---

### 5. POST /api/v1/checkout/cancel
**Cancel checkout and release slot**

Only works if payment not yet verified.

**Request:**
```json
{
  "checkout_id": "CHECKOUT_9773609077_1727000000"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Checkout cancelled"
}
```

**Results:**
- Slot reservation released (capacity increased)
- Checkout status set to `cancelled`
- Cart can be modified again

**Errors:**
- `400` - Payment already verified (cannot cancel)
- `404` - Checkout not found

---

## Complete Flow Diagram

```
1. Cart Ready
   ↓
2. POST /checkout/init
   ├─ Validate cart
   ├─ Lock pricing
   ├─ Reserve slot (15 min)
   └─ Return checkout_id
   ↓
3. Show Razorpay Form
   ├─ Use razorpay_order_id
   ├─ User enters payment details
   └─ Get razorpay_response
   ↓
4. POST /checkout/verify-payment (server-to-server)
   ├─ Verify signature
   ├─ Create booking
   ├─ Create order
   ├─ Save payment details
   └─ Return booking_id
   ↓
5. Show Confirmation
   ├─ Display booking details
   ├─ Show booking ID
   └─ Offer to view booking
```

---

## Error Handling

All errors follow standard format:
```json
{
  "success": false,
  "message": "Descriptive error message"
}
```

**Common Errors:**

| Code | Error | Solution |
|------|-------|----------|
| 400 | Slot fully booked | Choose different time |
| 400 | Date in past | Choose future date |
| 400 | Invalid signature | Payment verification failed |
| 403 | Unauthorized | User not logged in |
| 404 | Checkout not found | Invalid checkout_id |
| 500 | Payment gateway not configured | Admin must set Razorpay keys |

---

## Configuration

Add to `api/config.php`:
```php
define('RAZORPAY_KEY_ID', 'rzp_live_xxxxx');
define('RAZORPAY_KEY_SECRET', 'secret_xxxxx');
```

Get keys from: https://dashboard.razorpay.com/app/settings/api-keys

---

## Testing

**Test Cards (Razorpay):**
```
Visa: 4111 1111 1111 1111
Mastercard: 5555 5555 5555 4444
Expiry: Any future date
CVV: Any 3 digits
```

**Test Flow:**
1. Add service to cart
2. POST /checkout/init
3. POST /checkout/payment-intent
4. Use test card to pay
5. POST /checkout/verify-payment with test response
6. GET /checkout/status to verify

---

## Database Tables Used

- `checkout_sessions` - Session tracking
- `carts` - Cart reference
- `bookings` - Final bookings
- `orders` - Order records
- `service_time_slots` - Slot reservations

---

## Security Notes

✅ All prices calculated on server (client cannot manipulate)  
✅ Slot reserved atomically (prevents double-booking)  
✅ Signature verified (prevents payment tampering)  
✅ Transactions ensure consistency  
✅ Payment ID required for refunds  

---

**Last Updated:** September 29, 2026  
**Phase:** 3 of 7 (Complete)
