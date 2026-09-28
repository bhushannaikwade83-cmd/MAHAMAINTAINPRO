# Database Migrations - MahaMaintain Pro Cart System

## Overview
These SQL files implement the complete database schema for the Swiggy-style service marketplace cart system.

## Files Included

### 1. `001_create_cart_tables.sql` (REQUIRED - Run First)
Creates 10 new tables:
- `carts` - Server-side cart storage
- `cart_items` - Individual items in cart
- `cart_item_addons` - Add-ons per cart item
- `service_packages` - Service variants (Basic/Standard/Premium)
- `service_addons` - Add-on options for services
- `checkout_sessions` - Temporary checkout state
- `cart_pricing` - Pricing snapshots
- `cart_discounts` - Coupon tracking
- `service_location_config` - Travel fees, taxes, serviceability
- `time_slot_availability` - Real-time slot management

**Run this first.** It has no dependencies on modifications.

### 2. `002_modify_existing_tables.sql` (REQUIRED - Run Second)
Modifies existing tables:
- `orders` - Adds cart_id, checkout_session_id, price_snapshot
- `order_items` - Adds package_id, addon_ids, duration_minutes
- `bookings` - Adds provider_id, confirmed_at, slot_reserved_until
- `service_time_slots` - Adds capacity tracking
- `addresses` - Fixes phone number length, adds PRIMARY KEY
- `coupons` - Adds provider/service/package filtering
- `users` - Adds phone, default_address_id
- `services` - Adds pricing configuration
- `vendors` - Adds rating and availability

Creates indexes and foreign keys for performance.

**Run this second.** It modifies existing tables safely.

### 3. `003_sample_data.sql` (OPTIONAL - For Testing)
Inserts sample data:
- Service packages for AC Service (Basic, Standard, Premium)
- Add-ons (Gas Refill, Deep Cleaning, Filter Replacement)
- Sample coupons (SAVE200, FIRST10, SAVE50)
- Service location configuration for Powai and Dombivli

**Run this last if you want test data.** Safe to run multiple times (uses INSERT...ON DUPLICATE KEY).

---

## How to Import

### Option 1: Using MySQL Client (Command Line)

```bash
# Navigate to database/migrations folder
cd /path/to/project/database/migrations

# Login to MySQL
mysql -u digitrix_maha_user -p digitrix_maha_maintain_pro

# In MySQL prompt, run:
source 001_create_cart_tables.sql;
source 002_modify_existing_tables.sql;
source 003_sample_data.sql;
```

### Option 2: Using phpMyAdmin

1. Open phpMyAdmin
2. Select database `digitrix_maha_maintain_pro`
3. Click "Import" tab
4. Click "Choose File" and select `001_create_cart_tables.sql`
5. Click "Go"
6. Repeat for `002_modify_existing_tables.sql`
7. Repeat for `003_sample_data.sql` (if you want test data)

### Option 3: Using MySQL Workbench

1. Open MySQL Workbench
2. Connect to your server
3. File → Open SQL Script → Select `001_create_cart_tables.sql`
4. Execute (Ctrl+Enter or Cmd+Enter)
5. Repeat for other files

---

## Important Notes

### ✅ Safe to Run Multiple Times
All three files use `CREATE TABLE IF NOT EXISTS` and `ON DUPLICATE KEY UPDATE`, so they won't fail if you run them again.

### ⚠️ Run in Order
ALWAYS run in this order:
1. 001_create_cart_tables.sql
2. 002_modify_existing_tables.sql
3. 003_sample_data.sql

### 🔄 Backup First
Before running, backup your database:
```bash
mysqldump -u digitrix_maha_user -p digitrix_maha_maintain_pro > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 🔐 Database Credentials
Update these in the commands if different:
- **Username:** `digitrix_maha_user`
- **Password:** `maha_user@70`
- **Database:** `digitrix_maha_maintain_pro`

---

## What Gets Created

### New Tables (10)
| Table | Purpose |
|-------|---------|
| `carts` | Server-side cart storage per user |
| `cart_items` | Individual service items in cart |
| `cart_item_addons` | Add-ons selected for each cart item |
| `service_packages` | Service variants (Basic/Standard/Premium) |
| `service_addons` | Add-on options for services |
| `checkout_sessions` | Temporary checkout state during payment |
| `cart_pricing` | Pricing snapshots for integrity |
| `cart_discounts` | Coupon/discount tracking |
| `service_location_config` | Travel fees, taxes, serviceability rules |
| `time_slot_availability` | Real-time slot booking status |

### Modified Tables (9)
- `orders` - Enhanced with cart tracking
- `order_items` - Better item tracking
- `bookings` - Provider and slot tracking
- `service_time_slots` - Capacity management
- `addresses` - Schema fixes
- `coupons` - Better validation
- `users` - Additional fields
- `services` - Configuration fields
- `vendors` - Availability tracking

### New Indexes (20+)
Optimized queries for:
- Cart operations
- Service lookups
- Slot availability
- Coupon validation

---

## Verification

After running all migrations, verify the setup:

```sql
-- Check new tables exist
SHOW TABLES LIKE 'cart%';
SHOW TABLES LIKE 'service_package%';
SHOW TABLES LIKE 'service_addon%';
SHOW TABLES LIKE 'checkout%';

-- Check modified columns exist
DESCRIBE orders;    -- Should have cart_id, checkout_session_id
DESCRIBE bookings;  -- Should have provider_id, confirmed_at

-- Check indexes
SHOW INDEX FROM carts;
SHOW INDEX FROM orders;

-- Check sample data (if loaded)
SELECT COUNT(*) FROM carts;
SELECT COUNT(*) FROM service_packages;
SELECT COUNT(*) FROM service_addons;
```

---

## Next Steps

After database setup:

1. **Phase 2:** Build PHP backend APIs in `/api`
2. **Phase 3:** Create checkout endpoints
3. **Phase 4:** Add coupon, slot, serviceability logic
4. **Phase 5:** Build Flutter frontend screens
5. **Phase 6:** Integrate Razorpay payment
6. **Phase 7:** Testing and optimization

---

## Support

If you encounter errors:

1. **"Table already exists"** → File has been run before; safe to ignore
2. **"Foreign key error"** → Run migrations in order
3. **"Unknown column"** → Previous migration didn't complete; check error log
4. **"Access denied"** → Check username/password/database name

Contact support with the error message and which migration file failed.

---

**Version:** 1.0  
**Last Updated:** September 29, 2026  
**Status:** Production Ready
