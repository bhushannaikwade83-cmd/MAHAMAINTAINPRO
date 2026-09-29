<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// JWT Authentication (Security Layer)
require_once 'jwt-auth.php';
$token = verifyJWTToken();

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
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        throw new Exception('Invalid input');
    }

    $orderId = $input['order_id'] ?? null;
    // phone_number from verified JWT, not client input
    $phoneNumber = $token['phone_number'];
    $userId = $phoneNumber;
    $addressId = !empty($input['address_id']) ? (int)$input['address_id'] : null;
    $totalAmount = (float)($input['total_amount'] ?? 0);
    $serviceCount = (int)($input['service_count'] ?? 0);
    $scheduledDate = $input['scheduled_date'] ?? null;
    $scheduledTime = $input['scheduled_time'] ?? null;
    $scheduledAt = null;
    if ($scheduledDate && $scheduledTime) {
        $parsed = strtotime("$scheduledDate $scheduledTime");
        if ($parsed !== false) {
            $scheduledAt = date('Y-m-d H:i:s', $parsed);
        }
    }

    if (!$orderId || !$addressId || $totalAmount <= 0) {
        throw new Exception('Missing required fields');
    }

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

    if (!$conn->query($createTable)) {
        throw new Exception("Table creation failed: " . $conn->error);
    }

    $checkCol = $conn->query("SHOW COLUMNS FROM orders LIKE 'scheduled_at'");
    if ($checkCol->num_rows === 0) {
        $conn->query("ALTER TABLE orders ADD COLUMN scheduled_at DATETIME NULL AFTER service_count");
    }
    $checkCol = $conn->query("SHOW COLUMNS FROM orders LIKE 'coupon_code'");
    if ($checkCol->num_rows === 0) {
        $conn->query("ALTER TABLE orders ADD COLUMN coupon_code VARCHAR(50) NULL");
        $conn->query("ALTER TABLE orders ADD COLUMN discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0");
    }
    $checkCol = $conn->query("SHOW COLUMNS FROM orders LIKE 'pincode'");
    if ($checkCol->num_rows === 0) {
        $conn->query("ALTER TABLE orders ADD COLUMN pincode VARCHAR(10) NULL AFTER address_id");
    }

    // Fetch pincode from address
    $pincode = null;
    if ($addressId) {
        $addrQuery = "SELECT pincode FROM addresses WHERE id = ?";
        $addrStmt = $conn->prepare($addrQuery);
        if ($addrStmt) {
            $addrStmt->bind_param("i", $addressId);
            $addrStmt->execute();
            $addrResult = $addrStmt->get_result();
            if ($addrRow = $addrResult->fetch_assoc()) {
                $pincode = $addrRow['pincode'];
            }
            $addrStmt->close();
        }
    }

    // total_amount here is a client-supplied estimate only, shown before
    // payment - it is NOT what the customer is actually charged. The real,
    // tamper-proof amount is recomputed server-side from order_items +
    // the verified coupon at create-razorpay-order.php time, once items
    // are saved, and overwrites this value then.
    $couponCode = isset($input['coupon_code']) ? trim(strtoupper($input['coupon_code'])) : null;

    // Insert order
    $query = "INSERT INTO orders (order_id, user_id, phone_number, address_id, pincode, total_amount, service_count, scheduled_at, coupon_code, payment_status, order_status)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'pending')";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param("sssisidiss", $orderId, $userId, $phoneNumber, $addressId, $pincode, $totalAmount, $serviceCount, $scheduledAt, $couponCode);

    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }
    $stmt->close();

    // Notify the customer their order was placed
    $conn->query("CREATE TABLE IF NOT EXISTS notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone_number VARCHAR(20) NOT NULL,
        title VARCHAR(255) NOT NULL,
        body TEXT,
        type VARCHAR(50) DEFAULT 'general',
        reference_id VARCHAR(100),
        is_read TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_phone (phone_number)
    )");
    $notifTitle = 'Order placed';
    $notifBody = "Your order $orderId has been placed successfully. We'll notify you as it progresses.";
    $notifStmt = $conn->prepare(
        "INSERT INTO notifications (phone_number, title, body, type, reference_id) VALUES (?, ?, ?, 'order', ?)"
    );
    if ($notifStmt) {
        $notifStmt->bind_param('ssss', $phoneNumber, $notifTitle, $notifBody, $orderId);
        $notifStmt->execute();
        $notifStmt->close();
    }

    // Real push (not just the silent in-app inbox row above) - "Booking confirmed"
    require_once 'push-notification-helper.php';
    sendPushToPhone($conn, $phoneNumber, $notifTitle, $notifBody, ['type' => 'order', 'order_id' => $orderId]);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Order created successfully',
        'order_id' => $orderId,
        'amount' => $totalAmount,
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Order creation error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
