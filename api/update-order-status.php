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
    $checkOrder = "SELECT id FROM orders WHERE id = ?";
    $stmt = $conn->prepare($checkOrder);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('i', $orderId);
    $stmt->execute();
    $result = $stmt->get_result();
    $stmt->close();

    if ($result->num_rows === 0) {
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
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
