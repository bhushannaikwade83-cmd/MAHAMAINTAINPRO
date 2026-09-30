<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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
    $phone = $_GET['phone'] ?? null;
    $filter = $_GET['filter'] ?? 'all';

    if (!$phone) {
        throw new Exception('Phone number is required');
    }

    error_log("DEBUG: Checking for ratings table...");

    // Simple query without any JOINs first
    $query = "
        SELECT
            o.id,
            o.order_id,
            o.total_amount as amount,
            o.order_status,
            o.completion_otp,
            o.created_at,
            o.pincode,
            o.vendor_id,
            GROUP_CONCAT(oi.service_name SEPARATOR ', ') as services
        FROM orders o
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.phone_number = ?
    ";

    if ($filter === 'pending') {
        $query .= " AND o.order_status IN ('pending', 'requested', 'accepted')";
    } elseif ($filter === 'completed') {
        $query .= " AND o.order_status = 'service_completed'";
    }

    $query .= " GROUP BY o.order_id ORDER BY o.created_at DESC LIMIT 50";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param('s', $phone);
    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }

    $result = $stmt->get_result();

    $orders = [];
    while ($row = $result->fetch_assoc()) {
        $orders[] = [
            'id' => (int)$row['id'],
            'order_id' => $row['order_id'],
            'amount' => (float)$row['amount'],
            'status' => $row['order_status'],
            'completion_otp' => $row['completion_otp'],
            'created_at' => $row['created_at'],
            'services' => $row['services'],
            'vendor_id' => $row['vendor_id'],
            'vendor_rating' => 0,
            'is_rated' => false,
        ];
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'orders' => $orders,
        'total' => count($orders),
        'debug' => 'Simplified query - ratings table ignored'
    ]);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'debug' => 'Error in simplified query'
    ]);
}

$conn->close();
?>
