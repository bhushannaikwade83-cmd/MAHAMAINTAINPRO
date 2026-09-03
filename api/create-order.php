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
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        throw new Exception('Invalid input');
    }

    $orderId = $input['order_id'] ?? null;
    $userId = $input['user_id'] ?? 'guest';
    $addressId = $input['address_id'] ?? null;
    $totalAmount = $input['total_amount'] ?? 0;
    $serviceCount = $input['service_count'] ?? 0;

    if (!$orderId || !$addressId || $totalAmount <= 0) {
        throw new Exception('Missing required fields');
    }

    // Create orders table if not exists
    $createTable = "CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id VARCHAR(50) UNIQUE NOT NULL,
        user_id VARCHAR(100),
        address_id INT,
        total_amount DECIMAL(10, 2),
        service_count INT,
        payment_status VARCHAR(50) DEFAULT 'pending',
        payment_id VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )";

    if (!$conn->query($createTable)) {
        throw new Exception("Table creation failed: " . $conn->error);
    }

    // Insert order
    $query = "INSERT INTO orders (order_id, user_id, address_id, total_amount, service_count, payment_status)
              VALUES (?, ?, ?, ?, ?, 'pending')";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param("ssidi", $orderId, $userId, $addressId, $totalAmount, $serviceCount);

    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Order created successfully',
        'order_id' => $orderId,
        'amount' => $totalAmount,
    ]);

    $stmt->close();

} catch (Exception $e) {
    http_response_code(400);
    error_log("Order creation error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
