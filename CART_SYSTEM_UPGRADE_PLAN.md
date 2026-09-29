# MahaMaintain Pro - Service Marketplace Cart System Upgrade Plan

## PHASE 1: ASSESSMENT

### Current State Analysis

#### ✅ EXISTING & REUSABLE

**Database Schema:**
- ✅ `carts` table - stores cart per user with status, pricing
- ✅ `cart_items` table - individual services with pricing
- ✅ `cart_item_addons` table - add-ons per item
- ✅ `service_packages` table - service variants (Basic/Standard/Premium)
- ✅ `service_addons` table - add-on options
- ✅ `checkout_sessions` table - payment state tracking
- ✅ `cart_pricing` table - pricing snapshot
- ✅ `service_location_config` table - location-based fees/tax
- ✅ `time_slot_availability` table - slot availability
- ✅ `coupons` table - discount management (inferred from schema)

**Backend Services:**
- ✅ `CartService.php` - core cart operations (add/update/remove items)
- ✅ `PricingService.php` - pricing calculation
- ✅ API endpoints in `/api/v1/cart/` - GET, POST, DELETE

**Frontend:**
- ✅ `CartService` (Dart) - local state management with ChangeNotifier
- ✅ `cart_screen.dart` - UI display
- ✅ `checkout_screen.dart` - payment flow
- ✅ SharedPreferences persistence for offline cache

#### ❌ GAPS / NEEDS IMPLEMENTATION

**Database Enhancements:**
- ❌ Guest cart tracking (guest_cart table)
- ❌ Cart activity logging (for analytics/debugging)
- ❌ Slot reservation/locking mechanism
- ❌ Provider availability status tracking
- ❌ Service location serviceability cache

**Backend APIs:**
- ❌ `POST /api/v1/cart/validate` - cart validation before checkout
- ❌ `POST /api/v1/cart/apply-coupon` - coupon validation & application
- ❌ `GET /api/v1/cart/available-slots` - get available slots for date
- ❌ `GET /api/v1/cart/available-providers` - get providers for service
- ❌ `POST /api/v1/checkout/create` - atomic checkout session creation
- ❌ `POST /api/v1/checkout/verify-payment` - server-side payment verification
- ❌ `POST /api/v1/cart/merge-guest` - merge guest cart into user cart
- ❌ `GET /api/v1/config/service-fees` - get configurable fees

**Business Logic:**
- ❌ Slot locking/reservation (prevent race condition)
- ❌ Price change detection & user acknowledgment
- ❌ Coupon eligibility validation (complex rules)
- ❌ Service availability checker (location + provider + date + slot)
- ❌ Same-item quantity merging logic (service + package + addons = unique key)
- ❌ Cart expiry enforcement (24-hour cleanup)
- ❌ Minimum booking value validation

**Frontend UX:**
- ❌ Modern Swiggy-style cart UI overhaul
- ❌ Cart drawer/mini cart after add to cart
- ❌ Bill summary with live recalculation
- ❌ Date/slot picker in cart flow
- ❌ Provider selection UI
- ❌ Location selector with fee display
- ❌ Coupon suggestion engine
- ❌ Price change notification
- ❌ Slot availability real-time updates
- ❌ Better empty state
- ❌ Sticky checkout CTA

**Security:**
- ⚠️ Partial - Price validation exists but needs hardening
- ❌ Slot race condition prevention
- ❌ Coupon abuse protection
- ❌ Quantity manipulation protection

---

## PHASE 2: IMPLEMENTATION PLAN

### Priority 1: Core Cart Validation (Week 1)

**A. Database Enhancements**
```sql
-- Add to existing cart/checkout schema:
ALTER TABLE carts ADD COLUMN guest_user_id VARCHAR(100) NULL;
ALTER TABLE carts ADD COLUMN provider_id INT NULL;
ALTER TABLE carts ADD COLUMN is_guest TINYINT(1) DEFAULT 0;

CREATE TABLE slot_reservations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cart_id VARCHAR(100),
  slot_id INT,
  reservation_expires_at TIMESTAMP,
  UNIQUE(slot_id, cart_id),
  FOREIGN KEY (cart_id) REFERENCES carts(cart_id)
);

CREATE TABLE cart_activity_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cart_id VARCHAR(100),
  action VARCHAR(50),
  old_data JSON,
  new_data JSON,
  created_at TIMESTAMP,
  INDEX idx_cart_id (cart_id)
);
```

**B. Core APIs to Build**

```
POST /api/v1/cart/validate
├─ Verify authentication
├─ Check service availability
├─ Validate packages & add-ons
├─ Check location serviceability
├─ Verify slot availability
├─ Calculate final price
├─ Check minimum booking value
└─ Return validation errors or OK

POST /api/v1/cart/apply-coupon
├─ Validate coupon exists & active
├─ Check eligibility (service, location, min value, etc.)
├─ Calculate discount
├─ Recalculate total
└─ Return updated cart with discount

POST /api/v1/checkout/create
├─ Call cart/validate
├─ Create checkout_session
├─ Lock pricing (freeze current prices)
├─ Reserve slot if needed
└─ Return checkout_id & amount for payment

POST /api/v1/checkout/verify-payment
├─ Verify payment with Razorpay
├─ If success → create booking
├─ If failed → keep cart alive for retry
└─ Clear cart only after booking confirmed
```

### Priority 2: Service Logic (Week 2)

**C. CartService.php Enhancements**

```php
class CartService {
  // EXISTING
  - addItem()
  - updateItem()
  - removeItem()
  - getCart()
  
  // NEW
  + validateCart() → {valid: bool, issues: []}
  + mergeItemIfIdentical() → {merged: bool, item_id: int}
  + recalculatePricing() → {pricing: {...}}
  + applyDiscount() → {discount: decimal, new_total: decimal}
  + reserveSlot() → {reserved: bool, expires_at: timestamp}
  + releaseSlot() → {released: bool}
  + checkMinimumValue() → {met: bool, required: decimal, current: decimal}
  + detectPriceChange() → {changed: bool, old_price, new_price}
}
```

**D. New Service Classes**

```php
class CouponService {
  + validateCoupon(code, user_id, cart_total) → {valid: bool, discount: decimal}
  + checkEligibility(coupon, context) → {eligible: bool, reason: string}
  + calculateDiscount(coupon, subtotal) → decimal
}

class ServiceAvailabilityChecker {
  + isServiceAvailable(service_id, location, date, slot) → bool
  + getAvailableSlots(service_id, location, date) → [slots]
  + getAvailableProviders(service_id, location) → [providers]
  + validateLocation(service_id, location_id) → {serviceable: bool, travel_fee: decimal, tax: decimal}
}

class SlotReservationManager {
  + reserveSlot(slot_id, cart_id) → {reserved: bool, expires_at: timestamp}
  + releaseSlot(cart_id) → bool
  + isSlotAvailable(slot_id, date) → bool
  + getSlotCapacity(slot_id, date) → {total: int, booked: int, available: int}
}

class BookingCreator {
  + createFromCart(cart_id, checkout_session) → {booking_id, order_id}
  + attachPaymentDetails(booking_id, razorpay_data)
  + validateBeforeCreation(cart_id) → {valid: bool, issues: []}
}
```

### Priority 3: Frontend UX Overhaul (Week 3)

**E. React/Flutter Components**

```
Cart Flow:
├─ ServiceCard "Add to Cart"
│  └─ → MiniCart Toast
│
├─ CartPage
│  ├─ CartItemsList
│  │  ├─ CartItemCard
│  │  │  ├─ Service image/name
│  │  │  ├─ Package selector
│  │  │  ├─ Add-ons display
│  │  │  ├─ Quantity controls
│  │  │  ├─ Edit button
│  │  │  └─ Remove button
│  │  │
│  │  └─ Empty state
│  │
│  ├─ CartForm (sidebar on desktop, scroll on mobile)
│  │  ├─ LocationSelector
│  │  │  ├─ Address list
│  │  │  └─ Shows travel fee for each
│  │  │
│  │  ├─ DatePicker
│  │  │
│  │  ├─ TimeSlotSelector
│  │  │  ├─ Available slots
│  │  │  └─ Real-time availability
│  │  │
│  │  ├─ ProviderSelector (if applicable)
│  │  │
│  │  ├─ CouponInput
│  │  │  ├─ Apply coupon field
│  │  │  ├─ Show eligible coupons
│  │  │  └─ Applied discount display
│  │  │
│  │  └─ BillSummary
│  │     ├─ Subtotal
│  │     ├─ Travel fee
│  │     ├─ Platform fee
│  │     ├─ Tax breakdown
│  │     ├─ Coupon discount
│  │     └─ TOTAL (sticky)
│  │
│  └─ ProceedButton (sticky on mobile)
│
└─ CheckoutFlow
   ├─ ValidateCart API
   ├─ ShowPriceChanges (if any)
   ├─ CreateCheckoutSession API
   ├─ RazorpayPayment
   ├─ PaymentVerification (backend)
   ├─ CreateBooking (backend)
   ├─ ShowConfirmation
   └─ ClearCart
```

### Priority 4: Security & Hardening (Week 4)

**F. Validation Layer**

```
Every cart/checkout operation must:
1. Verify JWT token
2. Verify user ownership
3. Server-calculate all prices
4. Validate service exists & active
5. Validate packages/add-ons
6. Validate location serviceability
7. Validate slot availability (at checkout time too)
8. Validate provider availability
9. Validate coupon eligibility
10. Verify payment server-side
11. Create booking atomically
```

**G. Protection Mechanisms**

```
- Rate limiting on add-to-cart
- Duplicate order detection
- Slot race condition handling (database transactions)
- Price manipulation detection
- Coupon abuse prevention
- Cart expiry enforcement
- Payment timeout handling
```

---

## PHASE 3: IMPLEMENTATION CHECKLIST

### Database (2-3 hours)
- [ ] Create new tables (guest_cart, slot_reservations, cart_activity_log)
- [ ] Add new columns to existing tables
- [ ] Create indexes for performance
- [ ] Add foreign key constraints

### Backend Services (5-6 hours)
- [ ] Enhance CartService.php with validation methods
- [ ] Create CouponService class
- [ ] Create ServiceAvailabilityChecker class
- [ ] Create SlotReservationManager class
- [ ] Create BookingCreator class
- [ ] Write comprehensive unit tests

### Backend APIs (6-8 hours)
- [ ] `POST /api/v1/cart/validate`
- [ ] `POST /api/v1/cart/apply-coupon`
- [ ] `GET /api/v1/cart/available-slots`
- [ ] `GET /api/v1/cart/available-providers`
- [ ] `POST /api/v1/checkout/create`
- [ ] `POST /api/v1/checkout/verify-payment`
- [ ] `POST /api/v1/cart/merge-guest`
- [ ] `GET /api/v1/config/fees`

### Frontend (8-10 hours)
- [ ] Redesign cart UI components
- [ ] Build LocationSelector
- [ ] Build DatePicker + TimeSlotSelector
- [ ] Build CouponInput with suggestions
- [ ] Build BillSummary component
- [ ] Implement cart persistence
- [ ] Add animations & transitions
- [ ] Mobile responsiveness

### Testing (4-5 hours)
- [ ] Add to cart flow
- [ ] Edit item
- [ ] Apply coupon
- [ ] Select location (fee updates)
- [ ] Select date/slot (availability check)
- [ ] Price change detection
- [ ] Unavailable service handling
- [ ] Payment success/failure
- [ ] Cart persistence
- [ ] Guest cart merge

### Total Estimate: 4-5 weeks (with parallelization possible)

---

## PHASE 4: MIGRATION STRATEGY

**Step 1: Backward Compatibility**
- Keep existing cart APIs working
- New validation happens in parallel
- Gradual rollout to 10% → 50% → 100%

**Step 2: Data Migration**
- Backfill missing fields in existing carts
- No data loss
- Test with production data copy

**Step 3: Monitoring**
- Track cart abandonment rate
- Monitor checkout time
- Alert on validation failures
- Track payment success rate

---

## KEY DECISIONS

1. **Server-Side Truth**: Cart stored server-side, frontend caches for UX
2. **Atomic Checkout**: Everything validated + locked before payment
3. **No Silent Changes**: User notified of any price/slot/availability changes
4. **Guest Support**: Guest carts can be merged into user accounts
5. **Concurrency**: Database transactions prevent slot double-booking
6. **Extensibility**: Easy to add new service models (quote-based, hourly, etc.)

---

## NOT CHANGING

- Authentication system
- Service listing/search
- Booking confirmation flow
- Provider onboarding
- Admin panel
- Analytics

---

## Next Steps

1. **Approval**: Confirm this plan aligns with business goals
2. **Resource**: Assign developer(s)
3. **Setup**: Create feature branch
4. **Implement**: Follow Phase 3 checklist
5. **QA**: Comprehensive testing
6. **Deploy**: Staged rollout
7. **Monitor**: Track KPIs

---

**Estimated Timeline**: 4-5 weeks
**Risk Level**: Medium (lots of validation, but isolated to cart)
**Impact**: High (core marketplace feature)
