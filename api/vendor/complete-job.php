<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// SECURITY: vendor_phone was previously trusted straight from the client -
// any vendor could submit a completion report (and additional_charges!)
// under another vendor's phone number. It's now derived from the caller's
// own JWT.
require_once __DIR__ . '/../jwt-auth.php';
$authToken = requireVendorRole();

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

    $orderId = $input['order_id'] ?? null;
    $vendorPhone = $authToken['phone_number'];
    $beforePhoto = $input['before_photo'] ?? null;
    $afterPhoto = $input['after_photo'] ?? null;
    $workDescription = $input['work_description'] ?? null;
    $partsUsed = $input['parts_used'] ?? null;
    $additionalCharges = floatval($input['additional_charges'] ?? 0);
    $remarks = $input['remarks'] ?? null;

    if (!$orderId || !$beforePhoto || !$afterPhoto) {
        throw new Exception('Missing required fields');
    }

    // Create job_completion_reports table if not exists
    $createTable = "
    CREATE TABLE IF NOT EXISTS job_completion_reports (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL,
        vendor_phone VARCHAR(20),
        before_photo_url VARCHAR(500),
        after_photo_url VARCHAR(500),
        work_description TEXT,
        parts_used TEXT,
        additional_charges DECIMAL(10,2) DEFAULT 0,
        remarks TEXT,
        report_status ENUM('submitted', 'verified', 'approved', 'rejected') DEFAULT 'submitted',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        INDEX idx_order (order_id),
        INDEX idx_vendor (vendor_phone)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ";

    if (!$conn->query($createTable)) {
        throw new Exception("Job completion table creation failed: " . $conn->error);
    }

    // Check if order exists and belongs to this vendor
    $checkOrder = "SELECT id FROM orders WHERE id = ? AND vendor_id = (SELECT id FROM vendors WHERE phone = ?)";
    $stmt = $conn->prepare($checkOrder);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('is', $orderId, $vendorPhone);
    $stmt->execute();
    $result = $stmt->get_result();
    $stmt->close();

    if ($result->num_rows === 0) {
        throw new Exception('Order not found or does not belong to this vendor');
    }

    // Insert completion report
    $insertReport = "
    INSERT INTO job_completion_reports
    (order_id, vendor_phone, before_photo_url, after_photo_url, work_description, parts_used, additional_charges, remarks)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ";

    $stmt = $conn->prepare($insertReport);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('isssssds', $orderId, $vendorPhone, $beforePhoto, $afterPhoto, $workDescription, $partsUsed, $additionalCharges, $remarks);

    if (!$stmt->execute()) {
        throw new Exception('Failed to insert completion report: ' . $stmt->error);
    }
    $stmt->close();

    // Update order status to service_completed
    $updateOrder = "UPDATE orders SET current_status = 'service_completed' WHERE id = ?";
    $stmt = $conn->prepare($updateOrder);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('i', $orderId);
    $stmt->execute();
    $stmt->close();

    // Insert status history
    $insertStatus = "INSERT INTO order_status (order_id, status, changed_by, remarks) VALUES (?, 'service_completed', 'vendor', ?)";
    $stmt = $conn->prepare($insertStatus);
    if (!$stmt) throw new Exception('Prepare failed: ' . $conn->error);
    $stmt->bind_param('is', $orderId, $remarks);
    $stmt->execute();
    $stmt->close();

    $phoneStmt = $conn->prepare('SELECT phone_number FROM orders WHERE id = ?');
    $phoneStmt->bind_param('i', $orderId);
    $phoneStmt->execute();
    $customerRow = $phoneStmt->get_result()->fetch_assoc();
    $phoneStmt->close();
    if ($customerRow && !empty($customerRow['phone_number'])) {
        require_once __DIR__ . '/../push-notification-helper.php';
        sendPushToPhone(
            $conn,
            $customerRow['phone_number'],
            'Service completed',
            'Your service has been completed. Thank you for using MahaMaintain Pro!',
            ['type' => 'service_completed', 'order_id' => (string)$orderId]
        );
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Job completion report submitted successfully',
        'order_id' => $orderId,
        'status' => 'service_completed'
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Complete job error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
