-- ============================================================================
-- PHASE 1: CART SYSTEM - CREATE NEW TABLES
-- MahaMaintain Pro Service Marketplace Cart
-- ============================================================================

-- 1. CARTS TABLE - Server-side cart storage
CREATE TABLE IF NOT EXISTS `carts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `cart_id` VARCHAR(100) UNIQUE NOT NULL COMMENT 'Unique cart identifier',
  `user_id` VARCHAR(100) NOT NULL COMMENT 'Phone number of user',
  `provider_id` INT NULL COMMENT 'FK to vendors table if provider-specific cart',
  `service_location_id` INT NULL COMMENT 'FK to addresses table',
  `status` ENUM('active', 'abandoned', 'converted_to_booking') DEFAULT 'active' COMMENT 'Cart status',
  `currency` VARCHAR(3) DEFAULT 'INR',
  `subtotal` DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Sum of all item prices',
  `discount_amount` DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Total discount from coupon',
  `service_fee` DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Platform/service fee',
  `travel_fee` DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Travel/visit fee',
  `tax_amount` DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Total tax',
  `total_amount` DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Final total',
  `coupon_id` INT NULL COMMENT 'FK to coupons table',
  `coupon_code` VARCHAR(50) NULL COMMENT 'Applied coupon code',
  `scheduled_date` DATE NULL COMMENT 'Scheduled service date',
  `scheduled_time_slot` VARCHAR(50) NULL COMMENT 'Scheduled time slot (e.g., 4:00 PM - 5:00 PM)',
  `is_guest_cart` TINYINT(1) DEFAULT 0 COMMENT '1 if guest cart, 0 if logged-in user',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NULL COMMENT 'Cart expiry time (24 hours from update)',

  INDEX idx_user_id (user_id),
  INDEX idx_cart_id (cart_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at),
  FOREIGN KEY (service_location_id) REFERENCES addresses(id) ON DELETE SET NULL,
  FOREIGN KEY (provider_id) REFERENCES vendors(id) ON DELETE SET NULL,
  FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. CART_ITEMS TABLE - Individual items in cart
CREATE TABLE IF NOT EXISTS `cart_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `cart_id` VARCHAR(100) NOT NULL COMMENT 'FK to carts.cart_id',
  `service_id` INT NOT NULL COMMENT 'FK to services table',
  `package_id` INT NULL COMMENT 'FK to service_packages table',
  `variant_id` INT NULL COMMENT 'Alternative variant identifier',
  `quantity` INT DEFAULT 1,
  `unit_price` DECIMAL(10, 2) NOT NULL COMMENT 'Price at time of adding to cart',
  `duration_minutes` INT NULL COMMENT 'Service duration in minutes',
  `item_subtotal` DECIMAL(10, 2) COMMENT 'quantity × unit_price + addons',
  `options` JSON NULL COMMENT 'Selected service options as JSON',
  `provider_id` INT NULL COMMENT 'If service has assigned provider',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_cart_id (cart_id),
  INDEX idx_service_id (service_id),
  FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
  FOREIGN KEY (provider_id) REFERENCES vendors(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. CART_ITEM_ADDONS TABLE - Add-ons per cart item
CREATE TABLE IF NOT EXISTS `cart_item_addons` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `cart_item_id` INT NOT NULL COMMENT 'FK to cart_items table',
  `addon_id` INT NOT NULL COMMENT 'FK to service_addons table',
  `addon_name` VARCHAR(255) NOT NULL,
  `addon_price` DECIMAL(10, 2) NOT NULL COMMENT 'Price of addon at time of selection',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_cart_item_id (cart_item_id),
  INDEX idx_addon_id (addon_id),
  FOREIGN KEY (cart_item_id) REFERENCES cart_items(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. SERVICE_PACKAGES TABLE - Service variants/tiers
CREATE TABLE IF NOT EXISTS `service_packages` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `service_id` INT NOT NULL COMMENT 'FK to services table',
  `name` VARCHAR(100) NOT NULL COMMENT 'e.g., Basic, Standard, Premium',
  `description` TEXT NULL,
  `price` DECIMAL(10, 2) NOT NULL,
  `duration_minutes` INT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `display_order` INT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_service_id (service_id),
  INDEX idx_is_active (is_active),
  FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. SERVICE_ADDONS TABLE - Add-on options for services
CREATE TABLE IF NOT EXISTS `service_addons` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `service_id` INT NOT NULL COMMENT 'FK to services table',
  `name` VARCHAR(100) NOT NULL COMMENT 'e.g., Gas Refill, Deep Cleaning',
  `description` TEXT NULL,
  `price` DECIMAL(10, 2) NOT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `is_optional` TINYINT(1) DEFAULT 1 COMMENT '1 = optional, 0 = required',
  `compatible_packages` JSON NULL COMMENT 'Array of package IDs this addon works with (null = all)',
  `display_order` INT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_service_id (service_id),
  INDEX idx_is_active (is_active),
  FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. CHECKOUT_SESSIONS TABLE - Temporary checkout state
CREATE TABLE IF NOT EXISTS `checkout_sessions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `checkout_id` VARCHAR(100) UNIQUE NOT NULL,
  `cart_id` VARCHAR(100) NOT NULL,
  `user_id` VARCHAR(100) NOT NULL,
  `status` ENUM('initiated', 'payment_pending', 'payment_verified', 'booking_created', 'failed', 'expired') DEFAULT 'initiated',
  `locked_pricing` JSON NOT NULL COMMENT 'Snapshot of pricing at checkout time',
  `razorpay_order_id` VARCHAR(100) NULL,
  `razorpay_payment_id` VARCHAR(100) NULL,
  `payment_amount` DECIMAL(10, 2) NOT NULL,
  `payment_method` VARCHAR(50) NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NULL COMMENT 'Checkout expires after 30 minutes',

  INDEX idx_checkout_id (checkout_id),
  INDEX idx_cart_id (cart_id),
  INDEX idx_user_id (user_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. CART_PRICING TABLE - Pricing snapshot
CREATE TABLE IF NOT EXISTS `cart_pricing` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `cart_id` VARCHAR(100) NOT NULL,
  `subtotal` DECIMAL(10, 2) DEFAULT 0.00,
  `addons_total` DECIMAL(10, 2) DEFAULT 0.00,
  `travel_fee` DECIMAL(10, 2) DEFAULT 0.00,
  `service_fee` DECIMAL(10, 2) DEFAULT 0.00,
  `tax_rate` DECIMAL(5, 2) DEFAULT 0.00,
  `tax_amount` DECIMAL(10, 2) DEFAULT 0.00,
  `discount_amount` DECIMAL(10, 2) DEFAULT 0.00,
  `total_amount` DECIMAL(10, 2) DEFAULT 0.00,
  `currency` VARCHAR(3) DEFAULT 'INR',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_cart_id (cart_id),
  FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. CART_DISCOUNTS TABLE - Coupon/discount tracking
CREATE TABLE IF NOT EXISTS `cart_discounts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `cart_id` VARCHAR(100) NOT NULL,
  `coupon_id` INT NOT NULL,
  `coupon_code` VARCHAR(50) NOT NULL,
  `discount_type` ENUM('percentage', 'fixed') DEFAULT 'percentage',
  `discount_value` DECIMAL(10, 2) NOT NULL,
  `discount_amount` DECIMAL(10, 2) NOT NULL COMMENT 'Calculated discount',
  `applied_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_cart_id (cart_id),
  INDEX idx_coupon_id (coupon_id),
  FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
  FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. SERVICE_LOCATION_CONFIG TABLE - Travel fees, taxes, serviceability
CREATE TABLE IF NOT EXISTS `service_location_config` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `service_id` INT NOT NULL COMMENT 'FK to services table',
  `pincode` VARCHAR(10) NOT NULL,
  `location_name` VARCHAR(255) NULL,
  `is_serviceable` TINYINT(1) DEFAULT 1,
  `travel_fee` DECIMAL(10, 2) DEFAULT 0.00,
  `tax_rate` DECIMAL(5, 2) DEFAULT 18.00 COMMENT 'Default GST 18%',
  `available_from` TIME NULL COMMENT 'Service available from time',
  `available_until` TIME NULL COMMENT 'Service available until time',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_service_id (service_id),
  INDEX idx_pincode (pincode),
  UNIQUE KEY unique_service_pincode (service_id, pincode),
  FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. TIME_SLOT_AVAILABILITY TABLE - Real-time slot management
CREATE TABLE IF NOT EXISTS `time_slot_availability` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `slot_id` INT NOT NULL COMMENT 'FK to service_time_slots table',
  `service_date` DATE NOT NULL,
  `total_capacity` INT DEFAULT 1,
  `booked_count` INT DEFAULT 0,
  `is_available` TINYINT(1) DEFAULT 1,
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_slot_id (slot_id),
  INDEX idx_service_date (service_date),
  INDEX idx_is_available (is_available),
  UNIQUE KEY unique_slot_date (slot_id, service_date),
  FOREIGN KEY (slot_id) REFERENCES service_time_slots(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- END OF PHASE 1 MIGRATIONS
-- ============================================================================
