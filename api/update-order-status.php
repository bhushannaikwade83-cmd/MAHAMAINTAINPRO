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

    $orderId = $input['order_id'] ?? null;
    $status = $input['status'] ?? null;
    $remarks = $input['remarks'] ?? null;
    $changedBy = $input['changed_by'] ?? 'system';

    if (!$orderId || !$status) {
        throw new Exception('Missing required fields: order_id, status');
    }

    // Valid statuses
    $validStatuses = [
        'requested',
        'accepted',
        'technician_assigned',
        'technician_on_the_way',
        'service_started',
        'service_completed',
        'cancelled',
        'on_hold'
    ];

    if (!in_array($status, $validStatuses)) {
        throw new Exception('Invalid status: ' . $status);
    }

    // Verify order exists
    $checkOrder = "SELECT id, phone_number, order_id FROM orders WHERE id = ?";
    $stmt = $conn->prepare($checkOrder);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('i', $orderId);
    $stmt->execute();
    $result = $stmt->get_result();
    $orderRow = $result->fetch_assoc();
    $stmt->close();

    if (!$orderRow) {
        throw new Exception('Order not found: ' . $orderId);
    }

    // Insert status history record
    $insertStatus = "INSERT INTO order_status (order_id, status, changed_by, remarks) VALUES (?, ?, ?, ?)";
    $stmt = $conn->prepare($insertStatus);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('isss', $orderId, $status, $changedBy, $remarks);

    if (!$stmt->execute()) {
        throw new Exception('Failed to insert status: ' . $stmt->error);
    }
    $stmt->close();

    // Update current_status in orders table
    $updateOrder = "UPDATE orders SET current_status = ? WHERE id = ?";
    $stmt = $conn->prepare($updateOrder);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('si', $status, $orderId);

    if (!$stmt->execute()) {
        throw new Exception('Failed to update order status: ' . $stmt->error);
    }
    $stmt->close();

    // Notify the customer - populates their in-app notification inbox
    $statusMessages = [
        'requested' => 'Your service request has been received.',
        'accepted' => 'Your order has been accepted.',
        'technician_assigned' => 'A technician has been assigned to your order.',
        'technician_on_the_way' => 'Your technician is on the way.',
        'service_started' => 'Your service has started.',
        'service_completed' => 'Your service has been completed.',
        'cancelled' => 'Your order has been cancelled.',
        'on_hold' => 'Your order has been put on hold.',
    ];
    $notifTitle = 'Order ' . $orderRow['order_id'] . ' update';
    $notifBody = $statusMessages[$status] ?? ('Order status changed to ' . $status);
    $createNotifTable = "CREATE TABLE IF NOT EXISTS notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone_number VARCHAR(20) NOT NULL,
        title VARCHAR(255) NOT NULL,
        body TEXT,
        type VARCHAR(50) DEFAULT 'general',
        reference_id VARCHAR(100),
        is_read TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_phone (phone_number)
    )";
    $conn->query($createNotifTable);
    $notifStmt = $conn->prepare(
        "INSERT INTO notifications (phone_number, title, body, type, reference_id) VALUES (?, ?, ?, 'order', ?)"
    );
    if ($notifStmt) {
        $orderIdStr = (string) $orderId;
        $notifStmt->bind_param('ssss', $orderRow['phone_number'], $notifTitle, $notifBody, $orderIdStr);
        $notifStmt->execute();
        $notifStmt->close();
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Order status updated successfully',
        'order_id' => $orderId,
        'status' => $status,
        'updated_at' => date('Y-m-d H:i:s')
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Update order status error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
