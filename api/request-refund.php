<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// The customer/resident flags a paid order or bill for a refund - this
// only marks it 'requested'; an admin/committee reviews and actually
// triggers the Razorpay refund via process-refund.php.
require_once 'jwt-auth.php';
$token = verifyJWTToken();

$data = json_decode(file_get_contents('php://input'), true);
$type = $data['type'] ?? null; // 'order' or 'bill'
$id = $data['id'] ?? null;
$reason = trim($data['reason'] ?? '');

if (!in_array($type, ['order', 'bill'], true) || !$id || $reason === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'type (order/bill), id and reason are required']);
    exit;
}

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

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
    if ($type === 'order') {
        // Ownership check: order must belong to the authenticated phone number.
        $stmt = $conn->prepare("
            UPDATE orders SET refund_status = 'requested', refund_reason = ?
            WHERE order_id = ? AND phone_number = ? AND payment_status = 'completed' AND refund_status = 'none'
        ");
        $stmt->bind_param('sss', $reason, $id, $token['phone_number']);
    } else {
        // Ownership check: bill's flat must be linked to this phone number.
        $stmt = $conn->prepare("
            UPDATE society_maintenance_bills b
            JOIN society_customers_individual m ON m.flat_id = b.flat_id
            SET b.refund_status = 'requested', b.refund_reason = ?
            WHERE b.id = ? AND m.phone = ? AND b.status = 'paid' AND b.refund_status = 'none'
        ");
        $stmt->bind_param('sis', $reason, $id, $token['phone_number']);
    }

    $stmt->execute();

    if ($stmt->affected_rows === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Not found, not yours, not paid, or already requested']);
        exit;
    }

    echo json_encode(['success' => true, 'message' => 'Refund requested - awaiting review']);
    $stmt->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
