<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

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
    // Create order_status table for tracking status history
    $createOrderStatusTable = "
    CREATE TABLE IF NOT EXISTS order_status (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL,
        status ENUM(
            'requested',
            'accepted',
            'technician_assigned',
            'technician_on_the_way',
            'service_started',
            'service_completed',
            'cancelled',
            'on_hold'
        ) NOT NULL,
        changed_by VARCHAR(50) DEFAULT 'system',
        remarks TEXT,
        changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        INDEX idx_order (order_id),
        INDEX idx_status (status),
        INDEX idx_changed_at (changed_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ";

    if (!$conn->query($createOrderStatusTable)) {
        throw new Exception("Order status table creation failed: " . $conn->error);
    }

    // Add current_status column to orders table if not exists
    $checkColumn = "SHOW COLUMNS FROM orders LIKE 'current_status'";
    $result = $conn->query($checkColumn);

    if ($result->num_rows === 0) {
        $addColumn = "ALTER TABLE orders ADD COLUMN current_status VARCHAR(50) DEFAULT 'requested' AFTER vendor_status";
        if (!$conn->query($addColumn)) {
            throw new Exception("Failed to add current_status column: " . $conn->error);
        }
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Order status table created/verified successfully',
        'tables' => ['order_status', 'orders (updated)']
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Order status table error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
