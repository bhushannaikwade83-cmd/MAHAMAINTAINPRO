# Production Deployment Guide - Cart System

## Database Migrations

**This is production code. No test data or sample data is included.**

### Step 1: Create New Tables
```bash
mysql -u digitrix_maha_user -p digitrix_maha_maintain_pro < database/migrations/001_create_cart_tables.sql
```

**Status:** ✅ Already imported successfully

### Step 2: Modify Existing Tables
```bash
mysql -u digitrix_maha_user -p digitrix_maha_maintain_pro < database/migrations/002_modify_existing_tables_PRODUCTION.sql
```

**What it does:**
- Adds cart tracking to `orders` table
- Adds package/addon tracking to `order_items` table
- Adds provider tracking to `bookings` table
- Adds capacity tracking to `service_time_slots` table
- Enhances `coupons` table for service-specific coupons
- Adds phone field to `users` table
- Adds configuration fields to `services` table
- Adds availability tracking to `vendors` table

**Safety:** All operations use `IF NOT EXISTS` - idempotent and safe to run multiple times

---

## Backend API Endpoints

All endpoints created in `/api/v1/` directory:

### Cart Operations
- `GET /api/v1/cart` - Fetch user's cart
- `POST /api/v1/cart/add-item` - Add service to cart
- `DELETE /api/v1/cart/remove-item` - Remove item
- `POST /api/v1/cart/clear` - Empty cart
- `POST /api/v1/cart/validate` - Validate before checkout

### Coupon Operations
- `POST /api/v1/coupon/validate` - Validate coupon eligibility

### Core Services
- `/api/services/cart_service.php` - CartService class
- `/api/services/pricing_service.php` - PricingService class

---

## Files Created

### Database (2 production files)
```
database/migrations/
  ├── 001_create_cart_tables.sql (new tables)
  └── 002_modify_existing_tables_PRODUCTION.sql (table modifications)
```

### Backend Services (2 files)
```
api/services/
  ├── cart_service.php (200 lines)
  └── pricing_service.php (250 lines)
```

### API Endpoints (6 files)
```
api/v1/
  ├── cart/
  │   ├── get-cart.php
  │   ├── add-item.php
  │   ├── remove-item.php
  │   ├── clear-cart.php
  │   └── validate.php
  └── coupon/
      └── validate.php
```

### Documentation
```
├── API_DOCUMENTATION.md (API reference)
├── DEVELOPER_GUIDE.md (usage examples)
└── PRODUCTION_DEPLOYMENT.md (this file)
```

**Total: 13 production files**

---

## Key Architecture Decisions

✅ **Server-Side Pricing:** All pricing calculated on backend, never from client  
✅ **Price Snapshots:** Complete pricing stored at checkout  
✅ **Atomic Transactions:** Database transactions prevent race conditions  
✅ **Reusable Services:** CartService and PricingService used across all APIs  
✅ **Idempotent Migrations:** Safe to run multiple times  

---

## Deployment Checklist

- [ ] Database migration 001 imported
- [ ] Database migration 002 imported
- [ ] Backend services copied to `/api/services/`
- [ ] API endpoints copied to `/api/v1/`
- [ ] JWT authentication configured in `api/jwt-auth.php`
- [ ] Database credentials set in `api/config.php`
- [ ] Test cart endpoints with valid JWT token

---

## Next Phase (Phase 3)

Checkout flow implementation:
- Checkout session initialization
- Razorpay payment integration
- Booking creation
- Transaction safety

---

**Status:** Production-ready  
**Last Updated:** September 29, 2026
