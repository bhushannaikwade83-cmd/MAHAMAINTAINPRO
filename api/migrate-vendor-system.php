<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

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

try {
    // Create vendors table
    $createVendors = "CREATE TABLE IF NOT EXISTS vendors (
        id INT AUTO_INCREMENT PRIMARY KEY,
        vendor_id VARCHAR(100) UNIQUE NOT NULL,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(20),
        email VARCHAR(255),
        rating DECIMAL(3, 2) DEFAULT 0,
        total_services INT DEFAULT 0,
        status VARCHAR(50) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
    $conn->query($createVendors);

    // Create vendor_pincodes table (mapping)
    $createMapping = "CREATE TABLE IF NOT EXISTS vendor_pincodes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        vendor_id VARCHAR(100) NOT NULL,
        pincode VARCHAR(10) NOT NULL,
        area_name VARCHAR(255),
        is_active BOOLEAN DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY unique_vendor_pincode (vendor_id, pincode),
        FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
    )";
    $conn->query($createMapping);

    // Add vendor_id to bookings table if not exists
    $checkColumn = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
                   WHERE TABLE_NAME='orders' AND COLUMN_NAME='vendor_id' AND TABLE_SCHEMA='{$database}'";
    $result = $conn->query($checkColumn);

    if ($result->num_rows == 0) {
        $addVendorId = "ALTER TABLE orders ADD COLUMN vendor_id VARCHAR(100) AFTER address_id";
        $conn->query($addVendorId);
    }

    // Add vendor_status to bookings table if not exists
    $checkColumn = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
                   WHERE TABLE_NAME='orders' AND COLUMN_NAME='vendor_status' AND TABLE_SCHEMA='{$database}'";
    $result = $conn->query($checkColumn);

    if ($result->num_rows == 0) {
        $addVendorStatus = "ALTER TABLE orders ADD COLUMN vendor_status VARCHAR(50) DEFAULT 'pending' AFTER vendor_id";
        $conn->query($addVendorStatus);
    }

    echo json_encode([
        'success' => true,
        'message' => 'Vendor system migrated successfully',
        'tables' => ['vendors', 'vendor_pincodes'],
        'columns_added' => ['vendor_id', 'vendor_status']
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Migration error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
