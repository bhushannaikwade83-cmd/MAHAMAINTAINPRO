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
    // Create orders table if not exists
    $createTable = "CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id VARCHAR(100) UNIQUE NOT NULL,
        user_id VARCHAR(100),
        address_id INT,
        total_amount DECIMAL(10, 2) NOT NULL,
        discount_amount DECIMAL(10, 2) DEFAULT 0,
        coupon_code VARCHAR(50),
        service_count INT DEFAULT 0,
        payment_method VARCHAR(50) DEFAULT 'RAZORPAY',
        payment_id VARCHAR(200),
        payment_status VARCHAR(50) DEFAULT 'pending',
        order_status VARCHAR(50) DEFAULT 'confirmed',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )";

    if (!$conn->query($createTable)) {
        throw new Exception("Table creation failed: " . $conn->error);
    }

    // Add payment_method column if not exists
    $checkColumn = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
                   WHERE TABLE_NAME='orders' AND COLUMN_NAME='payment_method' AND TABLE_SCHEMA='{$database}'";
    $result = $conn->query($checkColumn);

    if ($result->num_rows == 0) {
        $addColumn = "ALTER TABLE orders ADD COLUMN payment_method VARCHAR(50) DEFAULT 'RAZORPAY' AFTER service_count";
        if (!$conn->query($addColumn)) {
            throw new Exception("Add payment_method column failed: " . $conn->error);
        }
    }

    // Add payment_status column if not exists
    $checkColumn = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
                   WHERE TABLE_NAME='orders' AND COLUMN_NAME='payment_status' AND TABLE_SCHEMA='{$database}'";
    $result = $conn->query($checkColumn);

    if ($result->num_rows == 0) {
        $addColumn = "ALTER TABLE orders ADD COLUMN payment_status VARCHAR(50) DEFAULT 'pending' AFTER payment_id";
        if (!$conn->query($addColumn)) {
            throw new Exception("Add payment_status column failed: " . $conn->error);
        }
    }

    // Add order_status column if not exists
    $checkColumn = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
                   WHERE TABLE_NAME='orders' AND COLUMN_NAME='order_status' AND TABLE_SCHEMA='{$database}'";
    $result = $conn->query($checkColumn);

    if ($result->num_rows == 0) {
        $addColumn = "ALTER TABLE orders ADD COLUMN order_status VARCHAR(50) DEFAULT 'confirmed' AFTER payment_status";
        if (!$conn->query($addColumn)) {
            throw new Exception("Add order_status column failed: " . $conn->error);
        }
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Orders table migrated successfully',
        'columns' => [
            'order_id' => 'VARCHAR(100) - Unique order ID',
            'user_id' => 'VARCHAR(100) - User identifier',
            'address_id' => 'INT - Delivery address ID',
            'total_amount' => 'DECIMAL(10,2) - Total order amount',
            'discount_amount' => 'DECIMAL(10,2) - Discount applied',
            'coupon_code' => 'VARCHAR(50) - Applied coupon',
            'service_count' => 'INT - Number of services',
            'payment_method' => 'VARCHAR(50) - RAZORPAY, GOOGLEPAY, PHONEPE, BHIM, COD',
            'payment_id' => 'VARCHAR(200) - Payment transaction ID',
            'payment_status' => 'VARCHAR(50) - pending, completed, failed',
            'order_status' => 'VARCHAR(50) - confirmed, processing, delivered, cancelled',
            'created_at' => 'TIMESTAMP - Order creation time',
            'updated_at' => 'TIMESTAMP - Last update time'
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Migration error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
