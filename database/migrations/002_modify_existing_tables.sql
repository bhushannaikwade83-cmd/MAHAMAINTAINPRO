-- ============================================================================
-- PHASE 1: MODIFY EXISTING TABLES - PRODUCTION VERSION
-- MahaMaintain Pro Service Marketplace Cart
-- Safe, idempotent, minimal schema modifications
-- ============================================================================

-- 1. MODIFY ORDERS TABLE - Cart tracking and pricing
ALTER TABLE `orders`
ADD COLUMN IF NOT EXISTS `checkout_session_id` VARCHAR(100) NULL COMMENT 'FK to checkout_sessions',
ADD COLUMN IF NOT EXISTS `price_snapshot` JSON NULL COMMENT 'Complete pricing breakdown at checkout';

-- 2. MODIFY ORDER_ITEMS TABLE - Package and addon tracking
ALTER TABLE `order_items`
ADD COLUMN IF NOT EXISTS `package_id` INT NULL COMMENT 'FK to service_packages table',
ADD COLUMN IF NOT EXISTS `addon_ids` JSON NULL COMMENT 'Array of selected addon IDs',
ADD COLUMN IF NOT EXISTS `duration_minutes` INT NULL;

-- 3. MODIFY BOOKINGS TABLE - Provider and slot tracking
ALTER TABLE `bookings`
ADD COLUMN IF NOT EXISTS `provider_id` INT NULL COMMENT 'FK to vendors table',
ADD COLUMN IF NOT EXISTS `confirmed_at` TIMESTAMP NULL COMMENT 'When booking was confirmed',
ADD COLUMN IF NOT EXISTS `slot_reserved_until` TIMESTAMP NULL COMMENT 'Slot reservation expiry';

-- 4. MODIFY SERVICE_TIME_SLOTS TABLE - Capacity tracking
ALTER TABLE `service_time_slots`
ADD COLUMN IF NOT EXISTS `remaining_capacity` INT DEFAULT 1 COMMENT 'Available slots remaining',
ADD COLUMN IF NOT EXISTS `booked_count` INT DEFAULT 0 COMMENT 'Number of bookings for this slot';

-- 5. MODIFY COUPONS TABLE - Service-specific coupons
ALTER TABLE `coupons`
ADD COLUMN IF NOT EXISTS `provider_id` INT NULL COMMENT 'Coupon specific to provider',
ADD COLUMN IF NOT EXISTS `service_id` INT NULL COMMENT 'Coupon specific to service',
ADD COLUMN IF NOT EXISTS `package_id` INT NULL COMMENT 'Coupon specific to package',
ADD COLUMN IF NOT EXISTS `min_quantity` INT DEFAULT 1,
ADD COLUMN IF NOT EXISTS `is_first_order_only` TINYINT(1) DEFAULT 0,
ADD COLUMN IF NOT EXISTS `max_uses_per_user` INT DEFAULT NULL;

-- 6. MODIFY USERS TABLE - Phone field
ALTER TABLE `users`
ADD COLUMN IF NOT EXISTS `phone` VARCHAR(20) NULL UNIQUE COMMENT 'User phone number',
ADD COLUMN IF NOT EXISTS `default_address_id` INT NULL COMMENT 'FK to addresses table';

-- 7. MODIFY SERVICES TABLE - Service configuration
ALTER TABLE `services`
ADD COLUMN IF NOT EXISTS `min_booking_value` DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS `platform_fee` DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS `allows_addons` TINYINT(1) DEFAULT 1,
ADD COLUMN IF NOT EXISTS `requires_package_selection` TINYINT(1) DEFAULT 0,
ADD COLUMN IF NOT EXISTS `allows_quantity` TINYINT(1) DEFAULT 0;

-- 8. MODIFY VENDORS TABLE - Availability tracking
ALTER TABLE `vendors`
ADD COLUMN IF NOT EXISTS `average_rating` DECIMAL(3, 2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS `total_bookings` INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS `is_available_now` TINYINT(1) DEFAULT 1;

-- ============================================================================
-- END OF PRODUCTION MODIFICATIONS
-- ============================================================================
