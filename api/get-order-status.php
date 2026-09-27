<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

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
    // Get from GET or POST
    $orderId = $_GET['order_id'] ?? ($_POST['order_id'] ?? null);

    if (!$orderId) {
        throw new Exception('Missing required parameter: order_id');
    }

    // Get current order status
    $getOrder = "SELECT id, phone_number, current_status, created_at FROM orders WHERE id = ?";
    $stmt = $conn->prepare($getOrder);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('i', $orderId);
    $stmt->execute();
    $orderResult = $stmt->get_result();
    $stmt->close();

    if ($orderResult->num_rows === 0) {
        throw new Exception('Order not found: ' . $orderId);
    }

    $order = $orderResult->fetch_assoc();

    if ($order['phone_number'] !== $token['phone_number']) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'This order does not belong to you']));
    }

    // Get status history
    $getHistory = "SELECT status, changed_by, remarks, changed_at FROM order_status WHERE order_id = ? ORDER BY changed_at ASC";
    $stmt = $conn->prepare($getHistory);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('i', $orderId);
    $stmt->execute();
    $historyResult = $stmt->get_result();

    $statusHistory = [];
    while ($row = $historyResult->fetch_assoc()) {
        $statusHistory[] = [
            'status' => $row['status'],
            'changed_by' => $row['changed_by'],
            'remarks' => $row['remarks'],
            'changed_at' => $row['changed_at']
        ];
    }
    $stmt->close();

    // Status display names
    $statusNames = [
        'requested' => 'Order Requested',
        'accepted' => 'Order Accepted',
        'technician_assigned' => 'Technician Assigned',
        'technician_on_the_way' => 'Technician On The Way',
        'service_started' => 'Service Started',
        'service_completed' => 'Service Completed',
        'cancelled' => 'Order Cancelled',
        'on_hold' => 'Order On Hold'
    ];

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'order_id' => intval($orderId),
        'current_status' => $order['current_status'],
        'status_name' => $statusNames[$order['current_status']] ?? $order['current_status'],
        'status_history' => $statusHistory,
        'order_created_at' => $order['created_at']
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Get order status error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
