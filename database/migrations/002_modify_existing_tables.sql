-- ============================================================================
-- PHASE 1: CART SYSTEM - MODIFY EXISTING TABLES
-- MahaMaintain Pro Service Marketplace Cart
-- ============================================================================

-- 1. MODIFY ORDERS TABLE - Add cart tracking and price snapshots
ALTER TABLE `orders`
ADD COLUMN `cart_id` VARCHAR(100) NULL COMMENT 'FK to carts.cart_id' AFTER `order_id`,
ADD COLUMN `checkout_session_id` VARCHAR(100) NULL AFTER `cart_id`,
ADD COLUMN `price_snapshot` JSON NULL COMMENT 'Complete pricing breakdown at checkout' AFTER `checkout_session_id`,
ADD INDEX idx_cart_id (cart_id),
ADD INDEX idx_checkout_session_id (checkout_session_id);

-- 2. MODIFY ORDER_ITEMS TABLE - Better item tracking
ALTER TABLE `order_items`
ADD COLUMN `package_id` INT NULL COMMENT 'FK to service_packages table' AFTER `service_id`,
ADD COLUMN `addon_ids` JSON NULL COMMENT 'Array of selected addon IDs' AFTER `package_id`,
ADD COLUMN `option_ids` JSON NULL COMMENT 'Array of selected option IDs' AFTER `addon_ids`,
ADD COLUMN `duration_minutes` INT NULL AFTER `quantity`,
ADD INDEX idx_package_id (package_id);

-- 3. MODIFY BOOKINGS TABLE - Provider tracking and slot management
ALTER TABLE `bookings`
ADD COLUMN `provider_id` INT NULL COMMENT 'FK to vendors table' AFTER `vendor_id`,
ADD COLUMN `confirmed_at` TIMESTAMP NULL COMMENT 'When booking was confirmed' AFTER `completed_at`,
ADD COLUMN `slot_reserved_until` TIMESTAMP NULL COMMENT 'Slot reservation expiry' AFTER `confirmed_at`,
ADD INDEX idx_provider_id (provider_id);

-- 4. MODIFY SERVICE_TIME_SLOTS TABLE - Real-time availability
ALTER TABLE `service_time_slots`
ADD COLUMN `remaining_capacity` INT DEFAULT 1 COMMENT 'Available slots remaining' AFTER `id`,
ADD COLUMN `booked_count` INT DEFAULT 0 COMMENT 'Number of bookings for this slot' AFTER `remaining_capacity`,
ADD COLUMN `is_available` TINYINT(1) DEFAULT 1 COMMENT 'Real-time availability flag' AFTER `booked_count`,
ADD INDEX idx_is_available (is_available);

-- 5. MODIFY ADDRESSES TABLE - Fix schema issues
-- Make phone_number consistent (was VARCHAR(10), should be VARCHAR(20) for international)
ALTER TABLE `addresses` MODIFY COLUMN `phone_number` VARCHAR(20) NOT NULL;

-- Ensure addresses has PRIMARY KEY
ALTER TABLE `addresses` ADD PRIMARY KEY (`id`);

-- 6. MODIFY COUPONS TABLE - Better validation support
ALTER TABLE `coupons`
ADD COLUMN `provider_id` INT NULL COMMENT 'Coupon specific to provider (null = all)' AFTER `id`,
ADD COLUMN `service_id` INT NULL COMMENT 'Coupon specific to service (null = all)' AFTER `provider_id`,
ADD COLUMN `package_id` INT NULL COMMENT 'Coupon specific to package (null = all)' AFTER `service_id`,
ADD COLUMN `min_quantity` INT DEFAULT 1 AFTER `min_amount`,
ADD COLUMN `is_first_order_only` TINYINT(1) DEFAULT 0 AFTER `valid_until`,
ADD COLUMN `max_uses_per_user` INT DEFAULT NULL COMMENT 'Max uses by single user' AFTER `usage_count`,
ADD INDEX idx_provider_id (provider_id),
ADD INDEX idx_service_id (service_id);

-- 7. ENSURE USERS TABLE HAS REQUIRED FIELDS
-- Add phone field if not exists
ALTER TABLE `users`
ADD COLUMN `phone` VARCHAR(20) NULL UNIQUE COMMENT 'User phone number' AFTER `id`;

-- Add address if not exists
ALTER TABLE `users`
ADD COLUMN `default_address_id` INT NULL COMMENT 'FK to addresses table' AFTER `email`;

-- 8. MODIFY SERVICES TABLE - Add configuration fields
ALTER TABLE `services`
ADD COLUMN `min_booking_value` DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Minimum order value for service' AFTER `price`,
ADD COLUMN `platform_fee` DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Flat platform fee' AFTER `min_booking_value`,
ADD COLUMN `allows_addons` TINYINT(1) DEFAULT 1 COMMENT 'Whether this service allows add-ons' AFTER `platform_fee`,
ADD COLUMN `requires_package_selection` TINYINT(1) DEFAULT 0 COMMENT 'Whether package is mandatory' AFTER `allows_addons`,
ADD COLUMN `allows_quantity` TINYINT(1) DEFAULT 0 COMMENT 'Whether quantity can be > 1' AFTER `requires_package_selection`;

-- 9. MODIFY VENDORS TABLE - Add availability fields
ALTER TABLE `vendors`
ADD COLUMN `average_rating` DECIMAL(3, 2) DEFAULT 0.00 COMMENT 'Average service rating' AFTER `id`,
ADD COLUMN `total_bookings` INT DEFAULT 0 COMMENT 'Total completed bookings' AFTER `average_rating`,
ADD COLUMN `is_available_now` TINYINT(1) DEFAULT 1 COMMENT 'Real-time availability' AFTER `total_bookings`;

-- 10. ADD FOREIGN KEY CONSTRAINTS (where missing)
-- Add FK for vendor_id in bookings if not exists
ALTER TABLE `bookings`
ADD CONSTRAINT fk_bookings_vendor
FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE SET NULL;

-- Add FK for service_id in bookings if not exists
ALTER TABLE `bookings`
ADD CONSTRAINT fk_bookings_service
FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE SET NULL;

-- 11. ADD INDEXES FOR PERFORMANCE
-- Cart-related queries
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_bookings_user_phone ON bookings(customer_phone);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_created_at ON bookings(created_at);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(order_status);

-- Service queries
CREATE INDEX idx_services_category ON services(category_id);
CREATE INDEX idx_services_active ON services(is_active);

-- Time slot queries
CREATE INDEX idx_slots_service ON service_time_slots(service_id);
CREATE INDEX idx_slots_date ON service_time_slots(slot_date);

-- Coupon queries
CREATE INDEX idx_coupons_code ON coupons(code);
CREATE INDEX idx_coupons_active ON coupons(is_active);
CREATE INDEX idx_coupons_valid_from ON coupons(valid_from);
CREATE INDEX idx_coupons_valid_until ON coupons(valid_until);

-- 12. STANDARDIZE CHARSET (optional but recommended)
-- Convert all relevant tables to utf8mb4 for emoji/international support
ALTER TABLE `bookings` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `orders` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `services` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `vendors` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ============================================================================
-- END OF PHASE 1 MODIFICATIONS
-- ============================================================================
