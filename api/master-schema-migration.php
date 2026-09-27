<?php
/**
 * MASTER SCHEMA MIGRATION - both apps combined.
 *
 * Consolidates every CREATE TABLE / ALTER TABLE found scattered across
 * ~40 one-off migration/setup scripts in maha-maintainpro-main/api/ and
 * maha-vendor-app/server/*.sql - both apps deploy into the SAME physical
 * directory and share the SAME database (digitrix_maha_maintain_pro), so
 * this is the one place to run to get a brand-new database fully caught up,
 * or to verify an existing one has every column/table both apps expect.
 *
 * Safe to re-run any number of times: every statement is IF NOT EXISTS /
 * column-existence-checked, so nothing is dropped or overwritten.
 *
 * Admin-only, one-time-ish use - not a resident/vendor-facing endpoint.
 *
 * NOTE on `addresses`: no CREATE TABLE for it was ever found in code (it
 * predates every migration script and was presumably created by hand) -
 * its definition below is reconstructed from every INSERT/SELECT/UPDATE
 * that touches it across the app, not copied from an original source.
 * Verify against the live table before trusting it if you're rebuilding
 * from scratch.
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
requireAdminRole();

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

$applied = [];
$skipped = [];

function run($conn, $label, $sql, &$applied, &$skipped) {
    if ($conn->query($sql)) {
        $applied[] = $label;
    } else {
        $skipped[] = "$label ({$conn->error})";
    }
}

function addColumnIfMissing($conn, $table, $column, $definition, &$applied, &$skipped) {
    $check = $conn->prepare(
        "SELECT COUNT(*) AS n FROM information_schema.columns
         WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?"
    );
    $check->bind_param('ss', $table, $column);
    $check->execute();
    $exists = (int) $check->get_result()->fetch_assoc()['n'] > 0;
    $check->close();

    if ($exists) {
        $skipped[] = "$table.$column (already exists)";
        return;
    }
    if ($conn->query("ALTER TABLE `$table` ADD COLUMN `$column` $definition")) {
        $applied[] = "$table.$column";
    } else {
        $skipped[] = "$table.$column ({$conn->error})";
    }
}

// =====================================================================
// 1. CORE AUTH / IDENTITY
// =====================================================================

run($conn, 'individuals table', "CREATE TABLE IF NOT EXISTS individuals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    profile_picture_url VARCHAR(500),
    role VARCHAR(50) DEFAULT 'individual',
    address_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_phone (phone_number),
    UNIQUE KEY unique_email (email)
)", $applied, $skipped);

run($conn, 'otp_storage table', "CREATE TABLE IF NOT EXISTS otp_storage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
)", $applied, $skipped);

run($conn, 'user_mpin table', "CREATE TABLE IF NOT EXISTS user_mpin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    mpin_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", $applied, $skipped);

run($conn, 'admin_users table', "CREATE TABLE IF NOT EXISTS admin_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'super_admin') NOT NULL DEFAULT 'admin',
    full_name VARCHAR(255),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)", $applied, $skipped);

// Reconstructed from usage - see file header note.
run($conn, 'addresses table', "CREATE TABLE IF NOT EXISTS addresses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    label VARCHAR(50) DEFAULT 'Home',
    full_address TEXT,
    building_name VARCHAR(255),
    street VARCHAR(255),
    area VARCHAR(255),
    pincode VARCHAR(10),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
)", $applied, $skipped);

// FCM push tokens - separate lightweight table used by save-user-fcm.php /
// get-fcm-by-phone.php / push-notification-helper.php (NOT `individuals`).
run($conn, 'users (fcm) table', "CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255),
    fcm_token VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)", $applied, $skipped);

run($conn, 'sos_alerts table', "CREATE TABLE IF NOT EXISTS sos_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_phone VARCHAR(20) NOT NULL,
    user_name VARCHAR(255),
    user_fcm_token VARCHAR(500),
    location VARCHAR(500),
    contacts TEXT,
    emergency_fcm_tokens TEXT,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)", $applied, $skipped);

// =====================================================================
// 2. SERVICE CATALOG (home services)
// =====================================================================

run($conn, 'service_categories table', "CREATE TABLE IF NOT EXISTS service_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL UNIQUE,
    color VARCHAR(20),
    description TEXT,
    image_path VARCHAR(500),
    faqs TEXT,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", $applied, $skipped);

run($conn, 'services table', "CREATE TABLE IF NOT EXISTS services (
    id INT PRIMARY KEY AUTO_INCREMENT,
    category_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    price INT DEFAULT 0,
    duration VARCHAR(50),
    rating DECIMAL(3,2),
    notes TEXT,
    description TEXT,
    whats_included TEXT,
    whats_not_included TEXT,
    warranty_text VARCHAR(255),
    image_path VARCHAR(500),
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE CASCADE,
    INDEX idx_category (category_id),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", $applied, $skipped);

run($conn, 'coupons table', "CREATE TABLE IF NOT EXISTS coupons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    discount_type ENUM('percentage', 'fixed') DEFAULT 'percentage',
    discount_value DECIMAL(10, 2) NOT NULL,
    min_amount DECIMAL(10, 2) DEFAULT 0,
    max_discount DECIMAL(10, 2),
    usage_limit INT,
    usage_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT 1,
    valid_from DATETIME,
    valid_until DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)", $applied, $skipped);

// =====================================================================
// 3. ORDERS (home-service bookings, MahaMaintain Pro side)
// =====================================================================

run($conn, 'orders table', "CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50) UNIQUE NOT NULL,
    user_id VARCHAR(100),
    phone_number VARCHAR(20),
    address_id INT,
    total_amount DECIMAL(10, 2),
    service_count INT,
    scheduled_at DATETIME NULL,
    payment_status VARCHAR(50) DEFAULT 'pending',
    order_status VARCHAR(50) DEFAULT 'pending',
    payment_id VARCHAR(100),
    payment_method VARCHAR(50),
    vendor_id VARCHAR(100),
    vendor_status VARCHAR(50) DEFAULT 'pending',
    current_status VARCHAR(50) DEFAULT 'requested',
    coupon_code VARCHAR(50) NULL,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    razorpay_order_id VARCHAR(100) NULL,
    refund_status ENUM('none', 'requested', 'processed', 'rejected') NOT NULL DEFAULT 'none',
    refund_reason TEXT NULL,
    refund_id VARCHAR(100) NULL,
    refunded_amount DECIMAL(10,2) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)", $applied, $skipped);

run($conn, 'order_items table', "CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    service_id INT,
    service_name VARCHAR(255),
    category VARCHAR(100),
    price DECIMAL(10, 2),
    quantity INT DEFAULT 1,
    subtotal DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
)", $applied, $skipped);

run($conn, 'order_status table', "CREATE TABLE IF NOT EXISTS order_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    status ENUM(
        'requested', 'accepted', 'technician_assigned', 'technician_on_the_way',
        'service_started', 'service_completed', 'cancelled', 'on_hold'
    ) NOT NULL,
    changed_by VARCHAR(50) DEFAULT 'system',
    remarks TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    INDEX idx_order (order_id),
    INDEX idx_status (status),
    INDEX idx_changed_at (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", $applied, $skipped);

run($conn, 'job_completion_reports table', "CREATE TABLE IF NOT EXISTS job_completion_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    vendor_phone VARCHAR(20),
    before_photo_url VARCHAR(500),
    after_photo_url VARCHAR(500),
    work_description TEXT,
    parts_used TEXT,
    additional_charges DECIMAL(10,2) DEFAULT 0,
    remarks TEXT,
    report_status ENUM('submitted', 'verified', 'approved', 'rejected') DEFAULT 'submitted',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    INDEX idx_order (order_id),
    INDEX idx_vendor (vendor_phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", $applied, $skipped);

run($conn, 'notifications table', "CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    type VARCHAR(50) DEFAULT 'general',
    reference_id VARCHAR(100),
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
)", $applied, $skipped);

// =====================================================================
// 4. VENDORS (shared by both apps - maha-vendor-app owns the account,
// MahaMaintain Pro's admin panel reads/manages a subset of the same row)
// =====================================================================

run($conn, 'vendors table', "CREATE TABLE IF NOT EXISTS vendors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id VARCHAR(100) UNIQUE NULL,
    name VARCHAR(255) DEFAULT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) DEFAULT NULL,
    rating DECIMAL(3, 2) DEFAULT 0,
    average_rating DECIMAL(3,1) DEFAULT 5.0,
    total_services INT DEFAULT 0,
    total_jobs INT DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    is_online TINYINT(1) NOT NULL DEFAULT 1,
    current_latitude DECIMAL(10, 8) NULL,
    current_longitude DECIMAL(11, 8) NULL,
    last_location_update TIMESTAMP NULL,
    mpin_hash VARCHAR(255) NULL,
    mpin_attempts INT NOT NULL DEFAULT 0,
    mpin_locked_until DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_vendor_phone (phone)
)", $applied, $skipped);

// No FK to vendors(vendor_id) here on purpose: the live `vendors` table
// (confirmed by this migration's own "already exists" results for
// mpin_hash/is_online/etc.) is the vendor-app schema keyed by `id` INT,
// not the VARCHAR `vendor_id` column the older get-vendor-jobs.php
// version of this table assumed - the two "vendor_id" concepts in this
// codebase don't actually match, so a hard FK constraint here would be
// pointing at a column that doesn't reliably exist/align. Kept as a plain
// unconstrained column instead of failing the whole migration on it.
run($conn, 'vendor_pincodes table', "CREATE TABLE IF NOT EXISTS vendor_pincodes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id VARCHAR(100) NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    area_name VARCHAR(255),
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_vendor_pincode (vendor_id, pincode)
)", $applied, $skipped);

run($conn, 'vendor_otp_storage table', "CREATE TABLE IF NOT EXISTS vendor_otp_storage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(10) NOT NULL,
    otp VARCHAR(4) NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    UNIQUE KEY uq_vendor_otp_phone (phone_number)
)", $applied, $skipped);

run($conn, 'vendor_ledger table', "CREATE TABLE IF NOT EXISTS vendor_ledger (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    booking_id BIGINT NULL,
    entry_type ENUM('JOB_EARNING', 'WITHDRAWAL', 'BONUS', 'ADJUSTMENT') NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    description VARCHAR(255) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vendor_created (vendor_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", $applied, $skipped);

run($conn, 'vendor_society_directory table', "CREATE TABLE IF NOT EXISTS vendor_society_directory (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    phase VARCHAR(100) NULL,
    area VARCHAR(255) NOT NULL,
    units INT NOT NULL DEFAULT 0,
    contact_name VARCHAR(255) NULL,
    contact_phone VARCHAR(20) NULL,
    has_amc TINYINT(1) NOT NULL DEFAULT 0,
    access_notes VARCHAR(255) NULL,
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)", $applied, $skipped);

// --- Vendor KYC / DigiLocker verification ---

run($conn, 'vendor_verifications table', "CREATE TABLE IF NOT EXISTS vendor_verifications (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    verification_status ENUM('UNVERIFIED', 'DIGILOCKER_CONNECTED', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED') NOT NULL DEFAULT 'UNVERIFIED',
    digilocker_connected TINYINT(1) NOT NULL DEFAULT 0,
    digilocker_verified_at DATETIME NULL,
    identity_verified TINYINT(1) NOT NULL DEFAULT 0,
    pan_verified TINYINT(1) NOT NULL DEFAULT 0,
    gst_verified TINYINT(1) NOT NULL DEFAULT 0,
    document_count INT DEFAULT 0,
    all_documents_verified BOOLEAN DEFAULT FALSE,
    admin_review_notes TEXT,
    admin_reviewed_at DATETIME,
    admin_reviewed_by VARCHAR(255),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_vendor (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", $applied, $skipped);

run($conn, 'digilocker_oauth_sessions table', "CREATE TABLE IF NOT EXISTS digilocker_oauth_sessions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    state_token VARCHAR(128) NOT NULL UNIQUE,
    status ENUM('INITIATED', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'INITIATED',
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", $applied, $skipped);

run($conn, 'vendor_bank_accounts table', "CREATE TABLE IF NOT EXISTS vendor_bank_accounts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    account_holder_name VARCHAR(255) NOT NULL,
    account_number_last4 VARCHAR(4) NOT NULL,
    ifsc_code VARCHAR(11) NOT NULL,
    razorpay_contact_id VARCHAR(64) NULL,
    razorpay_fund_account_id VARCHAR(64) NULL,
    razorpay_validation_id VARCHAR(64) NULL,
    registered_name VARCHAR(255) NULL,
    name_match TINYINT(1) NULL,
    verification_status ENUM('PENDING', 'VERIFIED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    verified_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_vendor_bank (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", $applied, $skipped);

run($conn, 'vendor_service_categories table', "CREATE TABLE IF NOT EXISTS vendor_service_categories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    category_id INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_vendor_category (vendor_id, category_id),
    FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", $applied, $skipped);

run($conn, 'vendor_selfies table', "CREATE TABLE IF NOT EXISTS vendor_selfies (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    status ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at DATETIME NULL,
    UNIQUE KEY uniq_vendor_selfie (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", $applied, $skipped);

run($conn, 'vendor_digilocker_documents table', "CREATE TABLE IF NOT EXISTS vendor_digilocker_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id INT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    document_id VARCHAR(255) UNIQUE,
    aadhaar_number VARCHAR(12),
    aadhaar_name VARCHAR(255),
    aadhaar_dob DATE,
    aadhaar_gender VARCHAR(10),
    aadhaar_address TEXT,
    pan_number VARCHAR(10),
    pan_name VARCHAR(255),
    pan_father_name VARCHAR(255),
    pan_dob DATE,
    license_number VARCHAR(50),
    license_holder_name VARCHAR(255),
    license_valid_from DATE,
    license_valid_till DATE,
    license_categories VARCHAR(100),
    issue_date DATE,
    expiry_date DATE,
    raw_json_data LONGTEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
    INDEX idx_vendor_id (vendor_id),
    INDEX idx_document_type (document_type),
    INDEX idx_aadhaar (aadhaar_number),
    INDEX idx_pan (pan_number)
)", $applied, $skipped);

run($conn, 'vendor_verification_history table', "CREATE TABLE IF NOT EXISTS vendor_verification_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id INT NOT NULL,
    action VARCHAR(50) NOT NULL,
    previous_status VARCHAR(50),
    new_status VARCHAR(50),
    admin_id INT,
    admin_name VARCHAR(255),
    rejection_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
    INDEX idx_vendor_id (vendor_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
)", $applied, $skipped);

// =====================================================================
// 5. JOBS / BOOKINGS (maha-vendor-app's own job queue + newer
// service_requests system used by the live-tracking screens)
// =====================================================================

run($conn, 'bookings table', "CREATE TABLE IF NOT EXISTS bookings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    individual_id INT NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(10) NOT NULL,
    category_id INT NOT NULL,
    service_type VARCHAR(255) NOT NULL,
    notes TEXT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 7) NULL,
    longitude DECIMAL(10, 7) NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_mode ENUM('UPI', 'CASH', 'ONLINE') NOT NULL DEFAULT 'UPI',
    scheduled_at DATETIME NULL,
    vendor_id VARCHAR(128) NULL,
    order_id VARCHAR(50) NULL,
    status ENUM('REQUESTED', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'REJECTED') NOT NULL DEFAULT 'REQUESTED',
    before_photo_path VARCHAR(255) NULL,
    after_photo_path VARCHAR(255) NULL,
    completion_otp VARCHAR(6) NULL,
    work_description TEXT NULL,
    parts_used TEXT NULL,
    additional_charges DECIMAL(10,2) NULL,
    technician_remarks TEXT NULL,
    customer_signature_path VARCHAR(255) NULL,
    rating TINYINT NULL,
    rating_comment TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    accepted_at DATETIME NULL,
    started_at DATETIME NULL,
    completed_at DATETIME NULL,
    cancelled_at DATETIME NULL,
    FOREIGN KEY (category_id) REFERENCES service_categories(id),
    INDEX idx_category_status (category_id, status),
    INDEX idx_vendor_status (vendor_id, status),
    INDEX idx_order_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", $applied, $skipped);

run($conn, 'booking_rejections table', "CREATE TABLE IF NOT EXISTS booking_rejections (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    booking_id BIGINT NOT NULL,
    vendor_id VARCHAR(128) NOT NULL,
    reason VARCHAR(255) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_booking_vendor (booking_id, vendor_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", $applied, $skipped);

run($conn, 'service_requests table', "CREATE TABLE IF NOT EXISTS service_requests (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", $applied, $skipped);

run($conn, 'service_time_slots table', "CREATE TABLE IF NOT EXISTS service_time_slots (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", $applied, $skipped);

run($conn, 'vendor_live_locations table', "CREATE TABLE IF NOT EXISTS vendor_live_locations (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", $applied, $skipped);

// =====================================================================
// 6. SOCIETY MODULE (MahaMaintain Pro)
// =====================================================================

run($conn, 'societies table', "CREATE TABLE IF NOT EXISTS societies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(10),
    registration_number VARCHAR(100) NULL,
    registration_date DATE NULL,
    contact_phone VARCHAR(20) NULL,
    contact_email VARCHAR(150) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)", $applied, $skipped);

run($conn, 'society_secretaries table', "CREATE TABLE IF NOT EXISTS society_secretaries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    secretary_id VARCHAR(100) UNIQUE NOT NULL,
    society_id INT NULL,
    user_id INT,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    status VARCHAR(50) DEFAULT 'not_active',
    approval_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_user_id (user_id)
)", $applied, $skipped);

run($conn, 'society_services table', "CREATE TABLE IF NOT EXISTS society_services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    secretary_id VARCHAR(100) NOT NULL,
    service_name VARCHAR(255) NOT NULL,
    service_icon VARCHAR(50),
    is_active BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (secretary_id) REFERENCES society_secretaries(secretary_id)
)", $applied, $skipped);

run($conn, 'society_customers_individual table', "CREATE TABLE IF NOT EXISTS society_customers_individual (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    society_id INT NULL,
    secretary_name VARCHAR(255) NULL,
    phone VARCHAR(20) NULL,
    is_committee BOOLEAN DEFAULT 0,
    is_enabled BOOLEAN DEFAULT 1,
    designation VARCHAR(50) DEFAULT 'MEMBER',
    member_type ENUM('owner', 'tenant') NOT NULL DEFAULT 'owner',
    flat_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_user_id (user_id),
    KEY idx_is_committee (is_committee),
    KEY idx_is_enabled (is_enabled),
    FOREIGN KEY (user_id) REFERENCES individuals(id) ON DELETE CASCADE
)", $applied, $skipped);

run($conn, 'society_buildings table', "CREATE TABLE IF NOT EXISTS society_buildings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    society_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    wing VARCHAR(50) NULL,
    total_floors INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_society_id (society_id),
    FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE
)", $applied, $skipped);

run($conn, 'society_flats table', "CREATE TABLE IF NOT EXISTS society_flats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    society_id INT NOT NULL,
    building_id INT NULL,
    flat_number VARCHAR(20) NOT NULL,
    floor INT NULL,
    occupancy_status ENUM('occupied', 'vacant') NOT NULL DEFAULT 'vacant',
    owner_member_id INT NULL,
    tenant_member_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_society_id (society_id),
    KEY idx_building_id (building_id),
    UNIQUE KEY uniq_society_flat (society_id, flat_number),
    FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE,
    FOREIGN KEY (building_id) REFERENCES society_buildings(id) ON DELETE SET NULL
)", $applied, $skipped);

run($conn, 'society_complaints table', "CREATE TABLE IF NOT EXISTS society_complaints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    society_id INT NOT NULL,
    user_id INT NOT NULL,
    flat_id INT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    priority ENUM('low', 'medium', 'high') NOT NULL DEFAULT 'medium',
    photo_url VARCHAR(500) NULL,
    status ENUM('open', 'in_progress', 'resolved') NOT NULL DEFAULT 'open',
    resolution_remarks TEXT NULL,
    resolution_photo_url VARCHAR(500) NULL,
    assigned_vendor_id INT NULL,
    assigned_vendor_name VARCHAR(150) NULL,
    assigned_vendor_phone VARCHAR(20) NULL,
    customer_confirmed TINYINT(1) NOT NULL DEFAULT 0,
    reopened_count INT NOT NULL DEFAULT 0,
    linked_booking_id BIGINT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    KEY idx_society_id (society_id),
    KEY idx_user_id (user_id),
    KEY idx_status (status),
    FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE
)", $applied, $skipped);

run($conn, 'society_notices table', "CREATE TABLE IF NOT EXISTS society_notices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    society_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'general',
    posted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    KEY idx_society_id (society_id),
    FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE
)", $applied, $skipped);

run($conn, 'society_maintenance_bills table', "CREATE TABLE IF NOT EXISTS society_maintenance_bills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    society_id INT NOT NULL,
    flat_id INT NOT NULL,
    period_month CHAR(7) NOT NULL COMMENT 'YYYY-MM',
    amount DECIMAL(10,2) NOT NULL,
    late_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM('due', 'paid') NOT NULL DEFAULT 'due',
    due_date DATE NULL,
    paid_at TIMESTAMP NULL,
    payment_id VARCHAR(100) NULL,
    razorpay_order_id VARCHAR(100) NULL,
    refund_status ENUM('none', 'requested', 'processed', 'rejected') NOT NULL DEFAULT 'none',
    refund_reason TEXT NULL,
    refund_id VARCHAR(100) NULL,
    refunded_amount DECIMAL(10,2) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_society_id (society_id),
    KEY idx_flat_id (flat_id),
    KEY idx_status (status),
    UNIQUE KEY uniq_flat_period (flat_id, period_month),
    FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE,
    FOREIGN KEY (flat_id) REFERENCES society_flats(id) ON DELETE CASCADE
)", $applied, $skipped);

run($conn, 'society_documents table', "CREATE TABLE IF NOT EXISTS society_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    society_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    uploaded_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_society_id (society_id),
    FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE
)", $applied, $skipped);

// =====================================================================
// 8. ADMIN PANEL: home-screen banners, service packages, secretary
// approval inquiries (added when the admin panel was wired up properly)
// =====================================================================

run($conn, 'banners table', "CREATE TABLE IF NOT EXISTS banners (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    image_path VARCHAR(500) NOT NULL,
    link_type VARCHAR(50) NULL,
    link_value VARCHAR(255) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)", $applied, $skipped);

run($conn, 'service_packages table', "CREATE TABLE IF NOT EXISTS service_packages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT NULL,
    image_path VARCHAR(500) NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)", $applied, $skipped);

run($conn, 'service_package_items table', "CREATE TABLE IF NOT EXISTS service_package_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    package_id INT NOT NULL,
    service_id INT NOT NULL,
    UNIQUE KEY uniq_package_service (package_id, service_id),
    FOREIGN KEY (package_id) REFERENCES service_packages(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
)", $applied, $skipped);

// =====================================================================
// 7. COLUMN SELF-HEAL - the CREATE TABLE IF NOT EXISTS statements above
// only take effect on a brand-new database. On the real, already-running
// production database, every one of these tables already exists with an
// OLDER column set - these are the actual ALTER TABLE statements that
// were scattered across the ~40 original migration scripts, so an
// existing install ends up with every column both apps expect too.
// =====================================================================

// The live `orders` table pre-dates this migration script and was created
// with an older schema missing even these "base" columns - confirmed by a
// production error log: "Unknown column 'phone_number' in 'WHERE'". The
// CREATE TABLE IF NOT EXISTS above is a no-op against that existing table,
// so these were never actually being added until now.
addColumnIfMissing($conn, 'orders', 'phone_number', 'VARCHAR(20) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'address_id', 'INT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'total_amount', 'DECIMAL(10, 2) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'service_count', 'INT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'payment_status', "VARCHAR(50) DEFAULT 'pending'", $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'order_status', "VARCHAR(50) DEFAULT 'pending'", $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'payment_id', 'VARCHAR(100) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'payment_method', 'VARCHAR(50) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'scheduled_at', 'DATETIME NULL AFTER service_count', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'vendor_id', "VARCHAR(100) NULL", $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'vendor_status', "VARCHAR(50) DEFAULT 'pending'", $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'current_status', "VARCHAR(50) DEFAULT 'requested'", $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'coupon_code', 'VARCHAR(50) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'discount_amount', 'DECIMAL(10,2) NOT NULL DEFAULT 0', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'razorpay_order_id', 'VARCHAR(100) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'refund_status', "ENUM('none', 'requested', 'processed', 'rejected') NOT NULL DEFAULT 'none'", $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'refund_reason', 'TEXT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'refund_id', 'VARCHAR(100) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'orders', 'refunded_amount', 'DECIMAL(10,2) NULL', $applied, $skipped);

addColumnIfMissing($conn, 'service_categories', 'image_path', 'VARCHAR(500) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'service_categories', 'faqs', 'TEXT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'services', 'description', 'TEXT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'services', 'whats_included', 'TEXT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'services', 'whats_not_included', 'TEXT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'services', 'warranty_text', 'VARCHAR(255) NULL', $applied, $skipped);

addColumnIfMissing($conn, 'society_secretaries', 'society_id', 'INT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_secretaries', 'user_id', 'INT NULL', $applied, $skipped);

addColumnIfMissing($conn, 'society_customers_individual', 'society_id', 'INT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_customers_individual', 'secretary_name', 'VARCHAR(255) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_customers_individual', 'phone', 'VARCHAR(20) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_customers_individual', 'designation', "VARCHAR(50) DEFAULT 'MEMBER'", $applied, $skipped);
addColumnIfMissing($conn, 'society_customers_individual', 'member_type', "ENUM('owner', 'tenant') NOT NULL DEFAULT 'owner'", $applied, $skipped);
addColumnIfMissing($conn, 'society_customers_individual', 'flat_id', 'INT NULL', $applied, $skipped);

addColumnIfMissing($conn, 'societies', 'registration_number', 'VARCHAR(100) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'societies', 'registration_date', 'DATE NULL', $applied, $skipped);
addColumnIfMissing($conn, 'societies', 'contact_phone', 'VARCHAR(20) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'societies', 'contact_email', 'VARCHAR(150) NULL', $applied, $skipped);

addColumnIfMissing($conn, 'society_complaints', 'priority', "ENUM('low', 'medium', 'high') NOT NULL DEFAULT 'medium'", $applied, $skipped);
addColumnIfMissing($conn, 'society_complaints', 'photo_url', 'VARCHAR(500) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_complaints', 'resolution_remarks', 'TEXT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_complaints', 'resolution_photo_url', 'VARCHAR(500) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_complaints', 'assigned_vendor_id', 'INT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_complaints', 'assigned_vendor_name', 'VARCHAR(150) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_complaints', 'assigned_vendor_phone', 'VARCHAR(20) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_complaints', 'customer_confirmed', 'TINYINT(1) NOT NULL DEFAULT 0', $applied, $skipped);
addColumnIfMissing($conn, 'society_complaints', 'reopened_count', 'INT NOT NULL DEFAULT 0', $applied, $skipped);
addColumnIfMissing($conn, 'society_complaints', 'linked_booking_id', 'BIGINT NULL', $applied, $skipped);

addColumnIfMissing($conn, 'society_maintenance_bills', 'late_fee', 'DECIMAL(10,2) NOT NULL DEFAULT 0', $applied, $skipped);
addColumnIfMissing($conn, 'society_maintenance_bills', 'payment_id', 'VARCHAR(100) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_maintenance_bills', 'razorpay_order_id', 'VARCHAR(100) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_maintenance_bills', 'refund_status', "ENUM('none', 'requested', 'processed', 'rejected') NOT NULL DEFAULT 'none'", $applied, $skipped);
addColumnIfMissing($conn, 'society_maintenance_bills', 'refund_reason', 'TEXT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_maintenance_bills', 'refund_id', 'VARCHAR(100) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'society_maintenance_bills', 'refunded_amount', 'DECIMAL(10,2) NULL', $applied, $skipped);

addColumnIfMissing($conn, 'vendors', 'mpin_hash', 'VARCHAR(255) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'vendors', 'mpin_attempts', 'INT NOT NULL DEFAULT 0', $applied, $skipped);
addColumnIfMissing($conn, 'vendors', 'mpin_locked_until', 'DATETIME NULL', $applied, $skipped);
addColumnIfMissing($conn, 'vendors', 'is_online', 'TINYINT(1) NOT NULL DEFAULT 1', $applied, $skipped);
addColumnIfMissing($conn, 'vendors', 'current_latitude', 'DECIMAL(10, 8) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'vendors', 'current_longitude', 'DECIMAL(11, 8) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'vendors', 'last_location_update', 'TIMESTAMP NULL', $applied, $skipped);
addColumnIfMissing($conn, 'vendors', 'average_rating', 'DECIMAL(3,1) DEFAULT 5.0', $applied, $skipped);
addColumnIfMissing($conn, 'vendors', 'total_jobs', 'INT DEFAULT 0', $applied, $skipped);

addColumnIfMissing($conn, 'vendor_verifications', 'document_count', 'INT DEFAULT 0', $applied, $skipped);
addColumnIfMissing($conn, 'vendor_verifications', 'all_documents_verified', 'BOOLEAN DEFAULT FALSE', $applied, $skipped);
addColumnIfMissing($conn, 'vendor_verifications', 'admin_review_notes', 'TEXT', $applied, $skipped);
addColumnIfMissing($conn, 'vendor_verifications', 'admin_reviewed_at', 'DATETIME', $applied, $skipped);
addColumnIfMissing($conn, 'vendor_verifications', 'admin_reviewed_by', 'VARCHAR(255)', $applied, $skipped);

addColumnIfMissing($conn, 'bookings', 'order_id', 'VARCHAR(50) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'bookings', 'work_description', 'TEXT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'bookings', 'parts_used', 'TEXT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'bookings', 'additional_charges', 'DECIMAL(10,2) NULL', $applied, $skipped);
addColumnIfMissing($conn, 'bookings', 'technician_remarks', 'TEXT NULL', $applied, $skipped);
addColumnIfMissing($conn, 'bookings', 'customer_signature_path', 'VARCHAR(255) NULL', $applied, $skipped);

$conn->close();

echo json_encode([
    'success' => true,
    'message' => 'Master schema migration complete - both apps, one database.',
    'applied_count' => count($applied),
    'skipped_count' => count($skipped),
    'applied' => $applied,
    'skipped_or_already_exists' => $skipped,
]);
?>
