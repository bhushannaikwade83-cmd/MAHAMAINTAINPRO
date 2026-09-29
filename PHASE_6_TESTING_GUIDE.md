# Phase 6: Testing & Verification - Comprehensive Guide

## 📊 Testing Strategy

**Three-tier testing approach:**

1. **Unit Tests** - Individual services & components
2. **Widget Tests** - UI components in isolation
3. **Integration Tests** - Complete user flows
4. **E2E Tests** - Full payment scenarios (manual)

---

## 🧪 Unit Tests (Services)

### CheckoutService Tests
```dart
✅ initCheckout should lock prices and reserve slot
✅ createPaymentIntent should create Razorpay order
✅ verifyPayment should create booking on success
✅ getCheckoutStatus should return current state
✅ cancelCheckout should release slot reservation
✅ Should handle API errors gracefully
✅ Should handle network timeouts
✅ Should manage SharedPreferences caching
```

**Run:**
```bash
flutter test test/services/checkout_service_test.dart
```

---

### SlotService Tests
```dart
✅ getAvailableSlots should return slots for date
✅ getAvailableDates should return 30-day forecast
✅ checkSlotAvailability should verify capacity
✅ formatTime should convert 24h to 12h format
✅ formatDate should format date correctly
✅ Should handle empty slot results
✅ Should handle API errors
```

**Run:**
```bash
flutter test test/services/slot_service_test.dart
```

---

### LocationService Tests
```dart
✅ checkServiceability should validate location
✅ isValidPincode should validate 6-digit format
✅ getServiceabilityStatus should return user message
✅ Should handle unserviceable locations
✅ Should check business hours
✅ Should handle API errors
```

**Run:**
```bash
flutter test test/services/location_service_test.dart
```

---

### CancellationService Tests
```dart
✅ getCancellationPolicy should calculate refund
✅ cancelBooking should create refund record
✅ Should enforce 24h -> 80h -> 50h -> 0h refund tiers
✅ Should prevent cancellation <2 hours
✅ Should handle API errors
```

**Run:**
```bash
flutter test test/services/cancellation_service_test.dart
```

---

## 🎨 Widget Tests (UI Components)

### PriceBreakdown Tests
```dart
✅ Should display total price correctly
✅ Should expand/collapse breakdown on tap
✅ Should display discount when applicable
✅ Should show all breakdown items when expanded
✅ Should handle zero prices correctly
✅ Should format prices with currency symbol
✅ Should highlight important values
```

**Run:**
```bash
flutter test test/widgets/price_breakdown_test.dart
```

---

### SlotPicker Tests
```dart
✅ Should display available dates horizontally
✅ Should display time slots in grid
✅ Should indicate slot availability
✅ Should handle slot selection
✅ Should show loading state while fetching
✅ Should display error message on failure
✅ Should format dates (Today, Tomorrow, Mon, etc)
✅ Should disable full slots
```

**Run:**
```bash
flutter test test/widgets/slot_picker_test.dart
```

---

### CartItemCard Tests
```dart
✅ Should display service name and package
✅ Should show quantity controls (+ / -)
✅ Should display add-ons as chips
✅ Should show price breakdown
✅ Should handle remove button
✅ Should format prices correctly
✅ Should handle no add-ons scenario
```

**Run:**
```bash
flutter test test/widgets/cart_item_card_test.dart
```

---

## 🔗 Integration Tests (Complete Flows)

### Checkout Flow
```
1. Location Selection → Serviceability Check
2. Date Selection → Slot Loading
3. Time Slot Selection → Availability Verification
4. Price Review → Expansion Toggle
5. Proceed Button → Checkout Initialization
6. Payment Order → Razorpay Integration
7. Payment Processing → User Input
8. Payment Verification → Booking Creation
9. Confirmation → Booking Details Display
```

**Test Scenarios:**
- ✅ Happy path: complete checkout
- ✅ Location unavailable: show error, block checkout
- ✅ Slot fully booked: disable selection, suggest alternatives
- ✅ Checkout expired: release slot, restart
- ✅ Payment failed: rollback and retry
- ✅ Network error: offline handling

**Run:**
```bash
flutter test test/integration/checkout_flow_test.dart
```

---

### Cancellation Flow
```
1. View Booking Details
2. Check Cancellation Policy
3. Initiate Cancellation
4. Verify Refund Amount
5. Confirm Cancellation
6. Release Slot
7. Create Refund Record
8. Show Confirmation
```

**Test Scenarios:**
- ✅ Eligible for 100% refund (>24h)
- ✅ Eligible for 80% refund (6-24h)
- ✅ Eligible for 50% refund (2-6h)
- ✅ Not eligible for refund (<2h)
- ✅ Prevent cancellation if ineligible

**Run:**
```bash
flutter test test/integration/cancellation_flow_test.dart
```

---

## 🔐 Security & Error Tests

### Payment Security
```dart
✅ Verify Razorpay signature on backend
✅ Detect price tampering attempts
✅ Prevent client-side price modification
✅ Use original locked prices
✅ Validate payment amount matches order
```

### API Security
```dart
✅ Require JWT token on all requests
✅ Verify user ownership of resources
✅ Prevent unauthorized access
✅ Validate input data types
✅ Reject malformed requests
```

### Data Integrity
```dart
✅ No pricing calculated on client
✅ Cart not modified during checkout
✅ Slot capacity enforced server-side
✅ Double-booking prevention (FOR UPDATE locks)
✅ Atomic transactions for consistency
```

---

## 📋 Test Checklist

### Before Deployment
- [ ] All unit tests pass (100% green)
- [ ] All widget tests pass (100% green)
- [ ] All integration tests pass (100% green)
- [ ] Code coverage >80%
- [ ] No test warnings or errors
- [ ] Performance tests pass (< 500ms for API calls)
- [ ] Memory leaks checked (no leaks)

### Payment Testing (Manual)
- [ ] Success path: complete booking
- [ ] Payment decline: handle gracefully
- [ ] Network timeout: retry logic works
- [ ] Invalid signature: detected and rejected
- [ ] Concurrent bookings: one succeeds, others fail

### User Scenarios
- [ ] User adds to cart
- [ ] User selects location
- [ ] User picks date/time
- [ ] User reviews pricing
- [ ] User initiates payment
- [ ] User completes payment
- [ ] User sees confirmation
- [ ] User can cancel booking
- [ ] User sees refund

---

## 🚀 Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/services/checkout_service_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

### Run Tests in Watch Mode
```bash
flutter test --watch
```

### Run Tests with Verbose Output
```bash
flutter test --verbose
```

---

## 📊 Coverage Targets

| Component | Target | Status |
|-----------|--------|--------|
| Services | 95% | 🚧 |
| Widgets | 90% | 🚧 |
| Screens | 85% | 🚧 |
| Utilities | 100% | 🚧 |
| **Overall** | **85%** | 🚧 |

---

## 🐛 Test-Driven Debugging

### If a test fails:

1. **Read the error message carefully**
   - What assertion failed?
   - What was expected vs actual?

2. **Check mock data**
   - Are mocks returning correct data?
   - Are mock responses complete?

3. **Debug the service**
   - Add print statements
   - Check API integration
   - Verify error handling

4. **Fix the code**
   - Don't modify the test
   - Fix the implementation
   - Re-run the test

5. **Verify the fix**
   - Run test again
   - Run all related tests
   - Check for regressions

---

## 🔄 Continuous Testing

### Before Each Commit
```bash
flutter test
flutter analyze
flutter format --set-exit-if-changed .
```

### Before Push to Repository
```bash
flutter test --coverage
flutter pub pub outdated
```

### Before Release
```bash
flutter clean
flutter test
flutter build apk --release
flutter build ios --release
```

---

## 📈 Test Metrics

**What We Measure:**
- Code coverage (target: 85%+)
- Test pass rate (target: 100%)
- Test execution time (target: < 2 minutes)
- Build time (target: < 1 minute)
- Performance metrics (API < 500ms)

---

## 🎯 Test Priorities

### P0 (Critical)
- Checkout initialization (price locking)
- Payment verification (signature check)
- Booking creation (transaction safety)
- Slot reservation (double-booking prevention)

### P1 (High)
- Location serviceability
- Slot availability
- Cancellation policy
- Refund calculations

### P2 (Medium)
- UI component display
- Error messages
- Loading states
- Format helpers

### P3 (Low)
- Theme switching
- Animations
- Optional UI features

---

## 📚 Mock Data Usage

**In-memory mocks provided for:**
```dart
MockCartData           → Valid/empty carts
MockCheckoutData       → Checkout states
MockSlotData           → Available slots
MockLocationData       → Location scenarios
MockCancellationData   → Refund policies
MockErrorResponses     → Error scenarios
MockRazorpayResponse   → Payment responses
```

**Usage in tests:**
```dart
final cartData = MockCartData.validCart();
final slots = MockSlotData.availableSlots();
final policy = MockCancellationData.cancellationPolicy100Percent();
```

---

## ✅ Final Verification

**Before declaring Phase 6 complete:**

1. Run full test suite: `flutter test`
2. Check coverage report
3. Verify all P0 tests pass
4. Run performance tests
5. Test on real device
6. Check CI/CD pipeline
7. Document any known issues

---

## 📝 Known Issues & Workarounds

### Issue: Razorpay plugin mock
**Workaround:** Mock Razorpay response, skip actual payment in unit tests

### Issue: SharedPreferences in tests
**Workaround:** Use mockito to mock SharedPreferences

### Issue: Network timeouts
**Workaround:** Set test timeout to 10 seconds

---

**Status:** Phase 6 Testing Architecture Complete

**Next:** Implement all tests and achieve 85%+ code coverage
