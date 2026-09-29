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

    if (!$input || !isset($input['order_id']) || !isset($input['items'])) {
        throw new Exception('Missing required fields: order_id, items');
    }

    $orderId = $input['order_id'];
    $items = $input['items'];

    // Create order_items table if not exists
    $createTable = "CREATE TABLE IF NOT EXISTS order_items (
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
    )";

    if (!$conn->query($createTable)) {
        throw new Exception("Table creation failed: " . $conn->error);
    }

    // Clear existing items for this order (if any)
    $deleteQuery = "DELETE FROM order_items WHERE order_id = ?";
    $deleteStmt = $conn->prepare($deleteQuery);
    if (!$deleteStmt) {
        throw new Exception("Delete prepare failed: " . $conn->error);
    }
    $deleteStmt->bind_param("s", $orderId);
    $deleteStmt->execute();
    $deleteStmt->close();

    // Insert each item
    $query = "INSERT INTO order_items (order_id, service_id, service_name, category, price, quantity, subtotal)
              VALUES (?, ?, ?, ?, ?, ?, ?)";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $itemCount = 0;
    foreach ($items as $item) {
        $serviceId = intval($item['service_id'] ?? 0);
        $serviceName = $item['service_name'] ?? 'Unknown Service';
        $category = $item['category'] ?? 'General';
        $price = floatval($item['price'] ?? 0);
        $quantity = intval($item['quantity'] ?? 1);
        $subtotal = $price * $quantity;

        $stmt->bind_param("isisdid", $orderId, $serviceId, $serviceName, $category, $price, $quantity, $subtotal);

        if (!$stmt->execute()) {
            throw new Exception("Execute failed for item: " . $stmt->error);
        }
        $itemCount++;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => "Saved $itemCount order items",
        'order_id' => $orderId,
        'items_saved' => $itemCount,
    ]);

    $stmt->close();

} catch (Exception $e) {
    http_response_code(400);
    error_log("Order items save error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
