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
    $filter = $_GET['filter'] ?? 'all'; // all, pending, completed, rated

    if (!$phone) {
        throw new Exception('Phone number is required');
    }

    $query = "
        SELECT
            o.id,
            o.order_id,
            o.total_amount as amount,
            o.order_status,
            o.completion_otp,
            o.created_at,
            o.before_photo_url,
            o.after_photo_url,
            o.payment_screenshot_url,
            o.customer_signature_url,
            o.work_description,
            o.parts_used,
            o.additional_charges,
            o.pincode,
            o.vendor_id,
            a.full_address,
            GROUP_CONCAT(oi.service_name SEPARATOR ', ') as services,
            COALESCE(r.rating, 0) as vendor_rating,
            COALESCE(r.comment, '') as vendor_comment,
            v.name as vendor_name,
            ROUND(AVG(r2.rating), 1) as vendor_avg_rating
        FROM orders o
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        LEFT JOIN addresses a ON o.address_id = a.id
        LEFT JOIN ratings r ON o.order_id = r.order_id
        LEFT JOIN vendors v ON o.vendor_id = v.id
        LEFT JOIN ratings r2 ON o.vendor_id = r2.vendor_id
        WHERE o.phone_number = ?
    ";

    // Apply filter
    if ($filter === 'pending') {
        $query .= " AND o.order_status IN ('pending', 'requested', 'accepted')";
    } elseif ($filter === 'completed') {
        $query .= " AND o.order_status = 'service_completed'";
    } elseif ($filter === 'rated') {
        $query .= " AND r.rating IS NOT NULL";
    } elseif ($filter === 'unrated') {
        $query .= " AND o.order_status = 'service_completed' AND r.rating IS NULL";
    }

    $query .= " GROUP BY o.order_id ORDER BY o.created_at DESC LIMIT 50";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param('s', $phone);
    $stmt->execute();
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
            'address' => $row['full_address'],
            'pincode' => $row['pincode'],
            'services' => $row['services'],
            'vendor_id' => $row['vendor_id'],
            'vendor_name' => $row['vendor_name'],
            'vendor_rating' => (float)$row['vendor_avg_rating'],
            'photos' => [
                'before' => $row['before_photo_url'],
                'after' => $row['after_photo_url'],
                'payment' => $row['payment_screenshot_url'],
                'signature' => $row['customer_signature_url'],
            ],
            'work_details' => [
                'description' => $row['work_description'],
                'parts_used' => $row['parts_used'],
                'additional_charges' => (float)$row['additional_charges'],
            ],
            'my_rating' => (int)$row['vendor_rating'],
            'my_comment' => $row['vendor_comment'],
            'is_rated' => (int)$row['vendor_rating'] > 0,
        ];
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'orders' => $orders,
        'total' => count($orders),
    ]);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?>
