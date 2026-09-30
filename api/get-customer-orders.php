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

// Auto-create ratings table if it doesn't exist
$createRatingsSQL = "CREATE TABLE IF NOT EXISTS ratings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL UNIQUE,
    vendor_id INT NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    rating INT NOT NULL,
    comment TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_vendor_id (vendor_id),
    INDEX idx_customer_phone (customer_phone)
)";
$conn->query($createRatingsSQL);

try {
    $phone = $_GET['phone'] ?? null;
    $filter = $_GET['filter'] ?? 'all';

    if (!$phone) {
        throw new Exception('Phone number is required');
    }

    // Simple reliable query - NO ratings table dependency
    $query = "
        SELECT
            o.id,
            o.order_id,
            o.total_amount as amount,
            o.order_status as status,
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
            a.full_address as address,
            GROUP_CONCAT(DISTINCT oi.service_name SEPARATOR ', ') as services,
            v.name as vendor_name
        FROM orders o
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        LEFT JOIN addresses a ON o.address_id = a.id
        LEFT JOIN vendors v ON o.vendor_id = v.id
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
    $stmt->execute();
    $result = $stmt->get_result();

    $orders = [];
    while ($row = $result->fetch_assoc()) {
        $orders[] = [
            'id' => (int)$row['id'],
            'order_id' => $row['order_id'],
            'amount' => (float)$row['amount'],
            'status' => $row['status'],
            'completion_otp' => $row['completion_otp'] ?? '',
            'created_at' => $row['created_at'],
            'address' => $row['address'] ?? '',
            'pincode' => $row['pincode'] ?? '',
            'services' => $row['services'] ?? 'Service',
            'vendor_id' => (int)$row['vendor_id'],
            'vendor_name' => $row['vendor_name'] ?? '',
            'vendor_rating' => 0,
            'is_rated' => false,
            'photos' => [
                'before' => $row['before_photo_url'] ?? '',
                'after' => $row['after_photo_url'] ?? '',
                'payment' => $row['payment_screenshot_url'] ?? '',
                'signature' => $row['customer_signature_url'] ?? '',
            ],
            'work_details' => [
                'description' => $row['work_description'] ?? '',
                'parts_used' => $row['parts_used'] ?? '',
                'additional_charges' => (float)($row['additional_charges'] ?? 0),
            ],
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
