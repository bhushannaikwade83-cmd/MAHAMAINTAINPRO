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

    // Simple query - NO ratings table at all
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

    error_log('═══════════════════════════════════════');
    error_log('🔍 [get-customer-orders] START');
    error_log('📱 Phone param: "' . $phone . '"');
    error_log('🔎 Filter: "' . $filter . '"');
    error_log('🔍 SQL (first 200 chars): ' . substr($query, 0, 200));

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        error_log('❌ Prepare FAILED: ' . $conn->error);
        throw new Exception("Prepare failed: " . $conn->error);
    }
    error_log('✅ Statement prepared');

    $stmt->bind_param('s', $phone);
    if (!$stmt->execute()) {
        error_log('❌ Execute FAILED: ' . $stmt->error);
        throw new Exception("Execute failed: " . $stmt->error);
    }
    error_log('✅ Query executed');

    $result = $stmt->get_result();
    error_log('📊 Result rows: ' . $result->num_rows);

    if ($result->num_rows === 0) {
        error_log('⚠️ NO ROWS RETURNED!');
        $simpleCount = "SELECT COUNT(*) as cnt FROM orders WHERE phone_number = '$phone'";
        $cntResult = $conn->query($simpleCount);
        $cntRow = $cntResult->fetch_assoc();
        error_log('🔎 Simple count: ' . $cntRow['cnt'] . ' orders for phone ' . $phone);
    }
    error_log('═══════════════════════════════════════');

    $orders = [];
    while ($row = $result->fetch_assoc()) {
        error_log('📍 Processing order: ' . $row['order_id']);
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
            'vendor_id' => (int)($row['vendor_id'] ?? 0),
            'vendor_name' => $row['vendor_name'] ?? '',
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
