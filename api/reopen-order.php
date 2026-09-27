<?php
/**
 * Lets a customer flag a problem with a completed service, reopening it for
 * review. There's no "reopened" status in order_status's enum yet - this
 * uses 'on_hold' (already a valid value) to mean "needs attention", with
 * the customer's complaint text stored in the remarks column so
 * admin-get-orders.php / order_status history shows exactly what's wrong.
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
$token = verifyJWTToken();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Method not allowed']));
}

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

require_once 'ensure-orders-schema.php';
if (!$conn->connect_error) {
    ensureOrdersSchema($conn);
}
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$data = json_decode(file_get_contents('php://input'), true);
$orderIdInt = isset($data['order_id']) ? (int) $data['order_id'] : 0;
$reason = trim((string)($data['reason'] ?? ''));

if ($orderIdInt <= 0 || $reason === '') {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'order_id and reason are required']));
}

try {
    $stmt = $conn->prepare("SELECT order_id, phone_number, current_status FROM orders WHERE id = ?");
    $stmt->bind_param('i', $orderIdInt);
    $stmt->execute();
    $order = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$order) {
        throw new Exception('Order not found');
    }
    if ($order['phone_number'] !== $token['phone_number']) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'This order does not belong to you']));
    }
    if ($order['current_status'] !== 'service_completed') {
        throw new Exception('Only a completed order can be reopened');
    }

    $remarks = 'Customer reopened: ' . $reason;

    $insertStmt = $conn->prepare(
        "INSERT INTO order_status (order_id, status, changed_by, remarks) VALUES (?, 'on_hold', 'customer', ?)"
    );
    $insertStmt->bind_param('is', $orderIdInt, $remarks);
    $insertStmt->execute();
    $insertStmt->close();

    $updateStmt = $conn->prepare("UPDATE orders SET current_status = 'on_hold' WHERE id = ?");
    $updateStmt->bind_param('i', $orderIdInt);
    $updateStmt->execute();
    $updateStmt->close();

    // Notify - so the customer sees this reflected in their own inbox too
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
    $notifStmt = $conn->prepare(
        "INSERT INTO notifications (phone_number, title, body, type, reference_id) VALUES (?, 'Order reopened', ?, 'order', ?)"
    );
    $notifBody = "We've received your issue with order {$order['order_id']} and will follow up shortly.";
    $notifStmt->bind_param('sss', $order['phone_number'], $notifBody, $order['order_id']);
    $notifStmt->execute();
    $notifStmt->close();

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Your issue has been reported. We will get back to you shortly.']);
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
