<?php
/**
 * Complete Database Migration for Maha Maintain ↔ Maha Vendor Integration
 * Creates all necessary tables and updates existing tables for the booking system
 *
 * Run once: https://digitrixmedia.com/mahamaintainpro/api/migrate-integration.php
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

try {
    $pdo = new PDO(
        "mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user",
        "maha_user@70",
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"]
    );

    $results = [];

    // ===== TABLE 1: service_requests =====
    $results['service_requests'] = 'RUNNING...';
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS service_requests (
            id INT AUTO_INCREMENT PRIMARY KEY,
            customer_id INT,
            service_id INT,
            service_category_id INT,
            pincode VARCHAR(10) NOT NULL,
            location_address TEXT NOT NULL,
            latitude DECIMAL(10, 8),
            longitude DECIMAL(11, 8),
            booking_type ENUM('INSTANT', 'SLOT') DEFAULT 'INSTANT',
            scheduled_date DATE,
            scheduled_time TIME,
            time_slot_id INT,
            preferred_time_window VARCHAR(50),
            description TEXT,
            budget DECIMAL(10, 2),
            status ENUM('PENDING','ASSIGNED','EN_ROUTE','ARRIVED','IN_PROGRESS','COMPLETED','CANCELLED','REJECTED') DEFAULT 'PENDING',
            assigned_vendor_id INT,
            vendor_name VARCHAR(255),
            vendor_phone VARCHAR(20),
            vendor_photo_url VARCHAR(500),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            accepted_at DATETIME,
            arrived_at DATETIME,
            started_at DATETIME,
            completed_at DATETIME,
            cancelled_at DATETIME,
            rating INT,
            review TEXT,
            completion_notes TEXT,
            payment_status ENUM('PENDING','PAID','FAILED','REFUNDED') DEFAULT 'PENDING',
            payment_id VARCHAR(100),
            INDEX idx_customer (customer_id),
            INDEX idx_vendor (assigned_vendor_id),
            INDEX idx_status (status),
            INDEX idx_pincode (pincode),
            INDEX idx_category (service_category_id),
            INDEX idx_booking_type (booking_type),
            INDEX idx_created (created_at),
            INDEX idx_scheduled_date (scheduled_date)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    $results['service_requests'] = '✅ CREATED';

    // ===== TABLE 2: service_time_slots =====
    $results['service_time_slots'] = 'RUNNING...';
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS service_time_slots (
            id INT AUTO_INCREMENT PRIMARY KEY,
            service_category_id INT,
            availability_date DATE NOT NULL,
            slot_start_time TIME NOT NULL,
            slot_end_time TIME NOT NULL,
            slot_label VARCHAR(50),
            max_bookings INT DEFAULT 5,
            current_bookings INT DEFAULT 0,
            is_available TINYINT DEFAULT 1,
            base_price DECIMAL(10, 2),
            is_premium TINYINT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_category (service_category_id),
            INDEX idx_date (availability_date),
            INDEX idx_available (is_available),
            UNIQUE KEY unique_slot (service_category_id, availability_date, slot_start_time)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    $results['service_time_slots'] = '✅ CREATED';

    // ===== TABLE 3: vendor_live_locations =====
    $results['vendor_live_locations'] = 'RUNNING...';
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS vendor_live_locations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            request_id INT,
            vendor_id INT,
            latitude DECIMAL(10, 8) NOT NULL,
            longitude DECIMAL(11, 8) NOT NULL,
            speed DECIMAL(5, 2),
            accuracy DECIMAL(5, 2),
            heading DECIMAL(5, 2),
            device_info VARCHAR(255),
            battery_level INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_request (request_id),
            INDEX idx_vendor (vendor_id),
            INDEX idx_created (created_at),
            INDEX idx_request_created (request_id, created_at DESC)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    $results['vendor_live_locations'] = '✅ CREATED';

    // ===== TABLE 4: vendor_service_categories =====
    $results['vendor_service_categories'] = 'RUNNING...';
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS vendor_service_categories (
            id INT AUTO_INCREMENT PRIMARY KEY,
            vendor_id INT,
            service_category_id INT,
            is_active TINYINT DEFAULT 1,
            base_price DECIMAL(10, 2),
            average_duration VARCHAR(50),
            min_rating DECIMAL(3, 1) DEFAULT 0,
            available_pincodes VARCHAR(500),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_vendor (vendor_id),
            INDEX idx_category (service_category_id),
            INDEX idx_active (is_active),
            UNIQUE KEY unique_vendor_category (vendor_id, service_category_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    $results['vendor_service_categories'] = '✅ CREATED';

    // ===== UPDATE TABLE 5: vendors =====
    $results['vendors_update'] = 'RUNNING...';
    $columns_to_add = [
        'is_online' => 'TINYINT DEFAULT 0',
        'current_latitude' => 'DECIMAL(10, 8)',
        'current_longitude' => 'DECIMAL(11, 8)',
        'last_location_update' => 'TIMESTAMP',
        'average_rating' => 'DECIMAL(3, 1) DEFAULT 5.0',
        'total_jobs' => 'INT DEFAULT 0'
    ];

    foreach ($columns_to_add as $column => $type) {
        try {
            $pdo->exec("ALTER TABLE vendors ADD COLUMN $column $type");
        } catch (Exception $e) {
            if (strpos($e->getMessage(), 'Duplicate column') === false) {
                throw $e;
            }
        }
    }
    $results['vendors_update'] = '✅ UPDATED';

    // ===== UPDATE TABLE 6: service_categories =====
    $results['service_categories_update'] = 'RUNNING...';
    $cat_columns = [
        'booking_type' => "ENUM('INSTANT', 'SLOT', 'BOTH') DEFAULT 'BOTH'",
        'instant_available' => 'TINYINT DEFAULT 1',
        'slot_available' => 'TINYINT DEFAULT 1',
        'average_response_time' => 'INT DEFAULT 15'
    ];

    foreach ($cat_columns as $column => $type) {
        try {
            $pdo->exec("ALTER TABLE service_categories ADD COLUMN $column $type");
        } catch (Exception $e) {
            if (strpos($e->getMessage(), 'Duplicate column') === false) {
                throw $e;
            }
        }
    }
    $results['service_categories_update'] = '✅ UPDATED';

    echo json_encode([
        'success' => true,
        'message' => '✅ DATABASE MIGRATION COMPLETE',
        'timestamp' => date('Y-m-d H:i:s'),
        'results' => $results,
        'tables_created' => 4,
        'tables_updated' => 2,
        'total' => '6 tables/updates completed successfully',
        'next_step' => 'Phase 2: Create APIs (create-instant-request.php, vendor-get-instant-requests.php, etc)'
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT);
}
?>
