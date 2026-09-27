<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database connection failed']);
        exit;
    }

    // Check if table already exists
    $tableCheck = $conn->query("SHOW TABLES LIKE 'user_mpin'");

    if ($tableCheck->num_rows > 0) {
        echo json_encode(['success' => true, 'message' => 'user_mpin table already exists']);
        $conn->close();
        exit;
    }

    // Create user_mpin table
    $createTable = "
    CREATE TABLE user_mpin (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone_number VARCHAR(20) UNIQUE NOT NULL,
        mpin_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_phone (phone_number)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ";

    if ($conn->query($createTable)) {
        echo json_encode(['success' => true, 'message' => 'user_mpin table created successfully']);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Failed to create table: ' . $conn->error]);
    }

    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
