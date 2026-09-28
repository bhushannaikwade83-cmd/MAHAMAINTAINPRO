-- ============================================================================
-- PHASE 1: SAMPLE DATA FOR TESTING
-- MahaMaintain Pro Service Marketplace Cart - Test Data
-- ============================================================================

-- INSERT SERVICE PACKAGES (for AC Service)
INSERT INTO `service_packages` (`service_id`, `name`, `description`, `price`, `duration_minutes`, `is_active`, `display_order`)
SELECT id, 'Basic Package', 'Basic AC service with general maintenance', 499.00, 45, 1, 1
FROM services WHERE name LIKE '%AC%' LIMIT 1
ON DUPLICATE KEY UPDATE is_active=1;

INSERT INTO `service_packages` (`service_id`, `name`, `description`, `price`, `duration_minutes`, `is_active`, `display_order`)
SELECT id, 'Standard Package', 'Standard AC service with parts cleaning', 799.00, 60, 1, 2
FROM services WHERE name LIKE '%AC%' LIMIT 1
ON DUPLICATE KEY UPDATE is_active=1;

INSERT INTO `service_packages` (`service_id`, `name`, `description`, `price`, `duration_minutes`, `is_active`, `display_order`)
SELECT id, 'Premium Package', 'Premium AC service with complete overhaul', 1199.00, 90, 1, 3
FROM services WHERE name LIKE '%AC%' LIMIT 1
ON DUPLICATE KEY UPDATE is_active=1;

-- INSERT SERVICE ADDONS
INSERT INTO `service_addons` (`service_id`, `name`, `description`, `price`, `is_active`, `is_optional`, `display_order`)
SELECT id, 'Gas Refill', 'Refrigerant gas refill', 499.00, 1, 1, 1
FROM services WHERE name LIKE '%AC%' LIMIT 1
ON DUPLICATE KEY UPDATE is_active=1;

INSERT INTO `service_addons` (`service_id`, `name`, `description`, `price`, `is_active`, `is_optional`, `display_order`)
SELECT id, 'Deep Cleaning', 'Complete AC unit deep cleaning', 299.00, 1, 1, 2
FROM services WHERE name LIKE '%AC%' LIMIT 1
ON DUPLICATE KEY UPDATE is_active=1;

INSERT INTO `service_addons` (`service_id`, `name`, `description`, `price`, `is_active`, `is_optional`, `display_order`)
SELECT id, 'Filter Replacement', 'Replace AC filter with new one', 149.00, 1, 1, 3
FROM services WHERE name LIKE '%AC%' LIMIT 1
ON DUPLICATE KEY UPDATE is_active=1;

-- INSERT SERVICE LOCATION CONFIG (for Powai, Mumbai)
INSERT INTO `service_location_config` (`service_id`, `pincode`, `location_name`, `is_serviceable`, `travel_fee`, `tax_rate`, `available_from`, `available_until`)
SELECT id, '400076', 'Powai', 1, 0.00, 18.00, '08:00:00', '22:00:00'
FROM services WHERE name LIKE '%AC%' LIMIT 1
ON DUPLICATE KEY UPDATE is_serviceable=1;

-- INSERT SERVICE LOCATION CONFIG (for Dombivli)
INSERT INTO `service_location_config` (`service_id`, `pincode`, `location_name`, `is_serviceable`, `travel_fee`, `tax_rate`, `available_from`, `available_until`)
SELECT id, '421202', 'Dombivli', 1, 50.00, 18.00, '08:00:00', '22:00:00'
FROM services WHERE name LIKE '%AC%' LIMIT 1
ON DUPLICATE KEY UPDATE is_serviceable=1;

-- INSERT SAMPLE COUPONS
INSERT INTO `coupons` (`code`, `description`, `discount_type`, `discount_value`, `min_amount`, `max_discount`, `usage_limit`, `usage_count`, `is_active`, `valid_from`, `valid_until`, `is_first_order_only`)
VALUES
('SAVE200', 'Get ₹200 off on AC service', 'fixed', 200.00, 999.00, 200.00, 100, 0, 1, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 0),
('FIRST10', 'Get 10% off for first booking', 'percentage', 10.00, 500.00, 999.00, 1000, 0, 1, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 1),
('SAVE50', 'Get ₹50 off on minimum ₹500 order', 'fixed', 50.00, 500.00, 50.00, NULL, 0, 1, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 0)
ON DUPLICATE KEY UPDATE is_active=1;

-- CREATE SAMPLE CART (optional - for testing)
-- This creates a test cart for user phone 9773609077
INSERT INTO `carts` (`cart_id`, `user_id`, `service_location_id`, `status`, `currency`, `subtotal`, `discount_amount`, `service_fee`, `travel_fee`, `tax_amount`, `total_amount`)
VALUES
('CART_9773609077_001', '9773609077', 15, 'active', 'INR', 1298.00, 0.00, 0.00, 50.00, 211.00, 1559.00)
ON DUPLICATE KEY UPDATE updated_at=NOW();

-- ============================================================================
-- END OF SAMPLE DATA
-- ============================================================================
