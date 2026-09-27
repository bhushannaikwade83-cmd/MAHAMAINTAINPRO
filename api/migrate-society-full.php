<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Admin-only: this creates/extends the full Society Module schema
// (buildings/wings, flats, owner-vs-tenant, complaints, notices,
// maintenance bills, documents, registration/contact fields on societies).
require_once 'jwt-auth.php';
requireAdminRole();

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

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
        // Duplicate column/index/key errors are expected on re-run - not fatal.
        $skipped[] = "$label ({$conn->error})";
    }
}

// 1. Registration + contact details on societies
run($conn, 'societies.registration_number', "ALTER TABLE societies ADD COLUMN registration_number VARCHAR(100) NULL", $applied, $skipped);
run($conn, 'societies.registration_date', "ALTER TABLE societies ADD COLUMN registration_date DATE NULL", $applied, $skipped);
run($conn, 'societies.contact_phone', "ALTER TABLE societies ADD COLUMN contact_phone VARCHAR(20) NULL", $applied, $skipped);
run($conn, 'societies.contact_email', "ALTER TABLE societies ADD COLUMN contact_email VARCHAR(150) NULL", $applied, $skipped);

// 2. Buildings / Wings
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

// 3. Flats
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

// 4. Owner vs tenant distinction + flat link on existing member table
run($conn, 'society_customers_individual.member_type', "ALTER TABLE society_customers_individual ADD COLUMN member_type ENUM('owner', 'tenant') NOT NULL DEFAULT 'owner'", $applied, $skipped);
run($conn, 'society_customers_individual.flat_id', "ALTER TABLE society_customers_individual ADD COLUMN flat_id INT NULL", $applied, $skipped);

// 5. Complaints
run($conn, 'society_complaints table', "CREATE TABLE IF NOT EXISTS society_complaints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    society_id INT NOT NULL,
    user_id INT NOT NULL,
    flat_id INT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    status ENUM('open', 'in_progress', 'resolved') NOT NULL DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    KEY idx_society_id (society_id),
    KEY idx_user_id (user_id),
    KEY idx_status (status),
    FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE
)", $applied, $skipped);

// 6. Notices
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

// 7. Maintenance bills (backs Maintenance Due / Collection dashboard stats)
run($conn, 'society_maintenance_bills table', "CREATE TABLE IF NOT EXISTS society_maintenance_bills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    society_id INT NOT NULL,
    flat_id INT NOT NULL,
    period_month CHAR(7) NOT NULL COMMENT 'YYYY-MM',
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('due', 'paid') NOT NULL DEFAULT 'due',
    due_date DATE NULL,
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_society_id (society_id),
    KEY idx_flat_id (flat_id),
    KEY idx_status (status),
    UNIQUE KEY uniq_flat_period (flat_id, period_month),
    FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE,
    FOREIGN KEY (flat_id) REFERENCES society_flats(id) ON DELETE CASCADE
)", $applied, $skipped);

// 8. Society-level documents (distinct from vendor KYC documents)
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

// 9. Complaint Management extras: priority, photo evidence, resolution
// remarks, vendor assignment, customer confirmation, reopen tracking.
run($conn, 'society_complaints.priority', "ALTER TABLE society_complaints ADD COLUMN priority ENUM('low', 'medium', 'high') NOT NULL DEFAULT 'medium'", $applied, $skipped);
run($conn, 'society_complaints.photo_url', "ALTER TABLE society_complaints ADD COLUMN photo_url VARCHAR(500) NULL", $applied, $skipped);
run($conn, 'society_complaints.resolution_remarks', "ALTER TABLE society_complaints ADD COLUMN resolution_remarks TEXT NULL", $applied, $skipped);
run($conn, 'society_complaints.resolution_photo_url', "ALTER TABLE society_complaints ADD COLUMN resolution_photo_url VARCHAR(500) NULL", $applied, $skipped);
run($conn, 'society_complaints.assigned_vendor_name', "ALTER TABLE society_complaints ADD COLUMN assigned_vendor_name VARCHAR(150) NULL", $applied, $skipped);
run($conn, 'society_complaints.assigned_vendor_phone', "ALTER TABLE society_complaints ADD COLUMN assigned_vendor_phone VARCHAR(20) NULL", $applied, $skipped);
run($conn, 'society_complaints.assigned_vendor_id', "ALTER TABLE society_complaints ADD COLUMN assigned_vendor_id INT NULL", $applied, $skipped);
run($conn, 'society_complaints.linked_booking_id', "ALTER TABLE society_complaints ADD COLUMN linked_booking_id BIGINT NULL", $applied, $skipped);
run($conn, 'society_complaints.customer_confirmed', "ALTER TABLE society_complaints ADD COLUMN customer_confirmed TINYINT(1) NOT NULL DEFAULT 0", $applied, $skipped);
run($conn, 'society_complaints.reopened_count', "ALTER TABLE society_complaints ADD COLUMN reopened_count INT NOT NULL DEFAULT 0", $applied, $skipped);

// 10. Maintenance Billing extras: late fee + payment gateway linkage.
run($conn, 'society_maintenance_bills.late_fee', "ALTER TABLE society_maintenance_bills ADD COLUMN late_fee DECIMAL(10,2) NOT NULL DEFAULT 0", $applied, $skipped);
run($conn, 'society_maintenance_bills.payment_id', "ALTER TABLE society_maintenance_bills ADD COLUMN payment_id VARCHAR(100) NULL", $applied, $skipped);

$conn->close();

echo json_encode([
    'success' => true,
    'message' => 'Society Module schema migrated',
    'applied' => $applied,
    'skipped_or_already_exists' => $skipped,
]);
?>
