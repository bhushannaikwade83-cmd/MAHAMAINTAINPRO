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

    error_log("Respond to job: vendor_id=$vendorId, booking_id=$bookingId, action=$action");

    if (!$vendorId || !$bookingId || !$action) {
        throw new Exception('Missing required fields: vendor_id, booking_id, action');
    }

    if (!in_array($action, ['accept', 'reject'])) {
        throw new Exception('Action must be "accept" or "reject"');
    }

    // Verify this order exists and is available (vendor_id can be NULL for new orders)
    $checkQuery = "SELECT vendor_id, order_status FROM orders WHERE order_id = ?";
    $stmt = $conn->prepare($checkQuery);
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    $stmt->bind_param('s', $bookingId);
    $stmt->execute();
    $result = $stmt->get_result();
    $order = $result->fetch_assoc();
    $stmt->close();

    error_log("Order lookup for booking_id=$bookingId: " . ($order ? "FOUND" : "NOT FOUND"));

    if (!$order) {
        // Check if order exists with different format
        $debugQuery = "SELECT order_id FROM orders LIMIT 5";
        $debugResult = $conn->query($debugQuery);
        $sample = [];
        while ($row = $debugResult->fetch_assoc()) {
            $sample[] = $row['order_id'];
        }
        error_log("Sample order_ids in DB: " . json_encode($sample));
        throw new Exception('Order not found: ' . $bookingId);
    }

    // If vendor_id is already set AND it's different vendor, reject
    if (!empty($order['vendor_id']) && $order['vendor_id'] !== $vendorId) {
        throw new Exception('This order is already assigned to another vendor');
    }

    // For accept: verify order is still pending/requested
    if ($action === 'accept' && !in_array($order['order_status'], ['pending', 'requested'])) {
        throw new Exception('Order is no longer available');
    }

    // Update order status based on action
    $newStatus = ($action === 'accept') ? 'accepted' : 'rejected';
    $newVendorStatus = ($action === 'accept') ? 'accepted' : 'rejected';

    // For accept: update vendor_id and both statuses. For reject: update both statuses
    if ($action === 'accept') {
        $updateQuery = "UPDATE orders SET vendor_id = ?, order_status = ?, vendor_status = ?, updated_at = NOW() WHERE order_id = ?";
        $stmt = $conn->prepare($updateQuery);
        if (!$stmt) {
            throw new Exception('Prepare failed: ' . $conn->error);
        }
        // Convert vendorId to integer for binding
        $vendorIdInt = (int)$vendorId;
        $stmt->bind_param('isss', $vendorIdInt, $newStatus, $newVendorStatus, $bookingId);
    } else {
        $updateQuery = "UPDATE orders SET order_status = ?, vendor_status = ?, updated_at = NOW() WHERE order_id = ?";
        $stmt = $conn->prepare($updateQuery);
        if (!$stmt) {
            throw new Exception('Prepare failed: ' . $conn->error);
        }
        $stmt->bind_param('sss', $newStatus, $newVendorStatus, $bookingId);
    }

    if (!$stmt->execute()) {
        throw new Exception('Update failed: ' . $stmt->error);
    }
    $stmt->close();

    // Log to order_status table for audit trail (use 'cancelled' instead of 'rejected')
    $logStatus = ($action === 'accept') ? 'accepted' : 'cancelled';

    // Get the order's numeric ID for logging
    $getIdQuery = "SELECT id FROM orders WHERE order_id = ?";
    $getIdStmt = $conn->prepare($getIdQuery);
    if (!$getIdStmt) {
        throw new Exception('Get ID prepare failed: ' . $conn->error);
    }
    $getIdStmt->bind_param('s', $bookingId);
    $getIdStmt->execute();
    $idResult = $getIdStmt->get_result();
    if ($idRow = $idResult->fetch_assoc()) {
        $orderId = $idRow['id'];
        $getIdStmt->close();

        $logQuery = "INSERT INTO order_status (order_id, status, changed_at) VALUES (?, ?, NOW())";
        $logStmt = $conn->prepare($logQuery);
        if (!$logStmt) {
            throw new Exception('Log prepare failed: ' . $conn->error);
        }
        $logStmt->bind_param('is', $orderId, $logStatus);
        if (!$logStmt->execute()) {
            error_log("Order status log failed: " . $logStmt->error);
        }
        $logStmt->close();
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Order ' . $action . 'ed successfully',
        'order_id' => $bookingId,
        'status' => $newStatus,
    ]);

} catch (Exception $e) {
    http_response_code(400);
    $errorMsg = $e->getMessage();
    error_log("Respond to job error: " . $errorMsg);
    echo json_encode(['success' => false, 'message' => $errorMsg, 'debug' => $errorMsg]);
}

$conn->close();
?>
