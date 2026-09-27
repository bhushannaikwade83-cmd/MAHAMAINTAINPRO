<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
$token = verifyJWTToken();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Method not allowed']));
}

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

require_once 'ensure-orders-schema.php';
if (!$conn->connect_error) {
    ensureOrdersSchema($conn);
}
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$data = json_decode(file_get_contents('php://input'), true);
$orderIdInt = isset($data['order_id']) ? (int) $data['order_id'] : 0;
$rating = isset($data['rating']) ? (int) $data['rating'] : 0;
$comment = trim((string)($data['comment'] ?? ''));

if ($orderIdInt <= 0 || $rating < 1 || $rating > 5) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'order_id and a rating (1-5) are required']));
}

try {
    // Order must belong to the requester and be completed before it can be rated
    $stmt = $conn->prepare("SELECT order_id, phone_number, current_status FROM orders WHERE id = ?");
    $stmt->bind_param('i', $orderIdInt);
    $stmt->execute();
    $order = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$order) {
        throw new Exception('Order not found');
    }
    if ($order['phone_number'] !== $token['phone_number']) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'This order does not belong to you']));
    }
    if ($order['current_status'] !== 'service_completed') {
        throw new Exception('You can only rate a completed service');
    }

    $updateStmt = $conn->prepare(
        "UPDATE bookings SET rating = ?, rating_comment = ? WHERE order_id = ?"
    );
    $updateStmt->bind_param('iss', $rating, $comment, $order['order_id']);
    $updateStmt->execute();
    $affected = $updateStmt->affected_rows;
    $updateStmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Thanks for your feedback!',
        'jobs_rated' => $affected,
    ]);
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
