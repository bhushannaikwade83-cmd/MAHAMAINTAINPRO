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
requireAdminRole();

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

require_once 'ensure-orders-schema.php';
if (!$conn->connect_error) {
    ensureOrdersSchema($conn);
}
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$statusFilter = $_GET['status'] ?? null;
$limit = isset($_GET['limit']) ? min((int) $_GET['limit'], 200) : 50;
$offset = isset($_GET['offset']) ? max((int) $_GET['offset'], 0) : 0;

try {
    $where = '';
    $params = [];
    $types = '';
    if ($statusFilter) {
        $where = 'WHERE o.current_status = ?';
        $params[] = $statusFilter;
        $types .= 's';
    }

    $query = "SELECT o.id, o.order_id, o.phone_number, o.address_id, o.total_amount, o.service_count,
                     o.scheduled_at, o.payment_status, o.current_status, o.payment_method, o.created_at,
                     i.full_name AS customer_name
              FROM orders o
              LEFT JOIN individuals i ON i.phone_number = o.phone_number
              $where
              ORDER BY o.created_at DESC
              LIMIT ? OFFSET ?";

    $stmt = $conn->prepare($query);
    $params[] = $limit;
    $params[] = $offset;
    $types .= 'ii';
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();

    $orders = [];
    while ($row = $result->fetch_assoc()) {
        $orders[] = $row;
    }
    $stmt->close();

    $countResult = $conn->query("SELECT COUNT(*) AS n FROM orders");
    $totalCount = (int) $countResult->fetch_assoc()['n'];

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'orders' => $orders,
        'total_count' => $totalCount,
        'limit' => $limit,
        'offset' => $offset,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
