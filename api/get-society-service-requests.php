<?php
/**
 * Society-wide view of resident service bookings (the orders/order_status
 * pipeline - see assign-vendor-to-order.php), so a committee/secretary can
 * see what services their residents have booked, not just complaints.
 * Previously there was no society-level listing at all for this.
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';

$societyId = isset($_GET['society_id']) ? (int) $_GET['society_id'] : 0;
if ($societyId <= 0) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'society_id is required']));
}

requireSocietyManagerRole($societyId);

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

require_once 'ensure-orders-schema.php';
if (!$conn->connect_error) {
    ensureOrdersSchema($conn);
}
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

try {
    $stmt = $conn->prepare(
        "SELECT o.order_id, o.phone_number, o.total_amount, o.service_count,
                o.current_status, o.scheduled_at, o.created_at,
                sci.secretary_name AS resident_name, sf.flat_number,
                GROUP_CONCAT(oi.service_name SEPARATOR ', ') AS services
         FROM orders o
         INNER JOIN society_customers_individual sci ON sci.phone = o.phone_number AND sci.society_id = ?
         LEFT JOIN society_flats sf ON sf.id = sci.flat_id
         LEFT JOIN order_items oi ON oi.order_id = o.order_id
         GROUP BY o.id
         ORDER BY o.created_at DESC
         LIMIT 100"
    );
    $stmt->bind_param('i', $societyId);
    $stmt->execute();
    $result = $stmt->get_result();

    $requests = [];
    while ($row = $result->fetch_assoc()) {
        $requests[] = $row;
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode(['success' => true, 'requests' => $requests, 'total' => count($requests)]);
} catch (Exception $e) {
    http_response_code(500);
    error_log('get-society-service-requests error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
