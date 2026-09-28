<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// JWT Authentication (Security Layer)
require_once 'jwt-auth.php';
$token = verifyJWTToken(); // This exits if invalid
$phoneFromToken = $token['phone_number']; // Get phone from secure JWT

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

require_once 'ensure-orders-schema.php';
if (!$conn->connect_error) {
    ensureOrdersSchema($conn);
}

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    // Use phone_number from JWT token (secure), not from request
    $phone = $phoneFromToken;

    // Create orders table if not exists
    $createTable = "CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id VARCHAR(50) UNIQUE NOT NULL,
        user_id VARCHAR(100),
        phone_number VARCHAR(20),
        address_id INT,
        total_amount DECIMAL(10, 2),
        service_count INT,
        payment_status VARCHAR(50) DEFAULT 'pending',
        order_status VARCHAR(50) DEFAULT 'pending',
        payment_id VARCHAR(100),
        payment_method VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )";

    $conn->query($createTable);

    // Fetch orders
    if ($phone) {
        // Search by phone number (for MahaMaintain Pro)
        $query = "SELECT * FROM orders WHERE phone_number = ? OR user_id = ? ORDER BY created_at DESC";
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("ss", $phone, $phone);
    } else {
        // Search by user_id
        $query = "SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC";
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        $stmt->bind_param("s", $userId);
    }

    $stmt->execute();
    $result = $stmt->get_result();

    $orders = [];
    while ($row = $result->fetch_assoc()) {
        // Fetch items for this order
        $itemQuery = "SELECT * FROM order_items WHERE order_id = ? ORDER BY id";
        $itemStmt = $conn->prepare($itemQuery);
        if ($itemStmt) {
            $itemStmt->bind_param("s", $row['order_id']);
            $itemStmt->execute();
            $itemResult = $itemStmt->get_result();

            $items = [];
            while ($itemRow = $itemResult->fetch_assoc()) {
                $items[] = $itemRow;
            }
            $row['items'] = $items;
            $itemStmt->close();
        } else {
            $row['items'] = [];
        }

        $orders[] = $row;
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'orders' => $orders,
        'total_orders' => count($orders),
    ]);

    $stmt->close();

} catch (Exception $e) {
    http_response_code(400);
    error_log("Get orders error: " . $e->getMessage());
    // TEMP DEBUG: revert to the generic message once the cause is found.
    echo json_encode(['success' => false, 'message' => 'DEBUG: ' . $e->getMessage()]);
}

$conn->close();
?>
