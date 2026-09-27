<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';

$type = $_GET['type'] ?? null; // 'order' or 'bill'
$society_id = isset($_GET['society_id']) ? (int)$_GET['society_id'] : null;

if (!in_array($type, ['order', 'bill'], true)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => "type must be 'order' or 'bill'"]);
    exit;
}

if ($type === 'order') {
    // Home-service orders aren't society-scoped - admin only.
    requireAdminRole();
} else {
    if (!$society_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'society_id is required for bill refund requests']);
        exit;
    }
    requireSocietyManagerRole($society_id);
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
        $stmt = $conn->prepare("
            SELECT order_id, phone_number, total_amount, payment_id, refund_reason, created_at
            FROM orders WHERE refund_status = 'requested' ORDER BY created_at DESC
        ");
        $stmt->execute();
        $result = $stmt->get_result();
        $requests = [];
        while ($row = $result->fetch_assoc()) $requests[] = $row;
    } else {
        $stmt = $conn->prepare("
            SELECT b.id, b.period_month, b.amount, b.late_fee, (b.amount + b.late_fee) AS total_amount,
                   f.flat_number, b.payment_id, b.refund_reason, b.paid_at
            FROM society_maintenance_bills b
            JOIN society_flats f ON f.id = b.flat_id
            WHERE b.society_id = ? AND b.refund_status = 'requested'
            ORDER BY b.paid_at DESC
        ");
        $stmt->bind_param('i', $society_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $requests = [];
        while ($row = $result->fetch_assoc()) $requests[] = $row;
    }

    echo json_encode(['success' => true, 'requests' => $requests, 'total' => count($requests)]);
    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}
?>
