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

    $vendorId = $input['vendor_id'] ?? null;
    $bookingId = $input['booking_id'] ?? null; // This is order_id
    $action = $input['action'] ?? null; // 'accept' or 'reject'

    if (!$vendorId || !$bookingId || !$action) {
        throw new Exception('Missing required fields: vendor_id, booking_id, action');
    }

    if (!in_array($action, ['accept', 'reject'])) {
        throw new Exception('Action must be "accept" or "reject"');
    }

    // Verify this order belongs to this vendor
    $checkQuery = "SELECT vendor_id, vendor_status FROM orders WHERE order_id = ?";
    $stmt = $conn->prepare($checkQuery);
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    $stmt->bind_param('s', $bookingId);
    $stmt->execute();
    $result = $stmt->get_result();
    $order = $result->fetch_assoc();
    $stmt->close();

    if (!$order) {
        throw new Exception('Order not found');
    }

    if ($order['vendor_id'] !== $vendorId) {
        throw new Exception('This order is not assigned to this vendor');
    }

    // Update order status based on action
    $newStatus = ($action === 'accept') ? 'accepted' : 'rejected';

    $updateQuery = "UPDATE orders SET vendor_status = ?, updated_at = NOW() WHERE order_id = ?";
    $stmt = $conn->prepare($updateQuery);
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    $stmt->bind_param('ss', $newStatus, $bookingId);

    if (!$stmt->execute()) {
        throw new Exception('Update failed: ' . $stmt->error);
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Order ' . $action . 'ed successfully',
        'order_id' => $bookingId,
        'status' => $newStatus,
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Respond to job error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
