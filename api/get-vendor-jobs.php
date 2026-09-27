<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

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
    echo json_encode(['success' => false, 'error' => 'Database connection failed']);
    exit();
}

try {
    $vendorId = $_GET['vendor_id'] ?? null;

    if (!$vendorId) {
        throw new Exception('vendor_id parameter required');
    }

    // Ensure tables exist
    $createVendors = "CREATE TABLE IF NOT EXISTS vendors (
        id INT AUTO_INCREMENT PRIMARY KEY,
        vendor_id VARCHAR(100) UNIQUE NOT NULL,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(20),
        email VARCHAR(255),
        rating DECIMAL(3, 2) DEFAULT 0,
        total_services INT DEFAULT 0,
        status VARCHAR(50) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
    $conn->query($createVendors);

    // Fetch NEW JOBS (orders pending vendor response)
    $newJobsQuery = "
        SELECT
            o.order_id as id,
            o.order_id,
            o.phone_number,
            o.total_amount as amount,
            o.order_status,
            o.vendor_status,
            o.created_at,
            GROUP_CONCAT(oi.service_name SEPARATOR ', ') as services,
            GROUP_CONCAT(oi.quantity SEPARATOR ', ') as quantities
        FROM orders o
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.vendor_id = ? AND o.vendor_status IN ('pending', 'new')
        GROUP BY o.order_id
        ORDER BY o.created_at DESC
        LIMIT 50
    ";

    $stmt = $conn->prepare($newJobsQuery);
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    $stmt->bind_param('s', $vendorId);
    $stmt->execute();
    $newJobsResult = $stmt->get_result();

    $newJobs = [];
    while ($row = $newJobsResult->fetch_assoc()) {
        $newJobs[] = $row;
    }
    $stmt->close();

    // Fetch MY JOBS (orders vendor has accepted)
    $myJobsQuery = "
        SELECT
            o.order_id as id,
            o.order_id,
            o.phone_number,
            o.total_amount as amount,
            o.order_status,
            o.vendor_status,
            o.created_at,
            GROUP_CONCAT(oi.service_name SEPARATOR ', ') as services
        FROM orders o
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.vendor_id = ? AND o.vendor_status IN ('accepted', 'in_progress', 'completed')
        GROUP BY o.order_id
        ORDER BY o.created_at DESC
        LIMIT 50
    ";

    $stmt = $conn->prepare($myJobsQuery);
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    $stmt->bind_param('s', $vendorId);
    $stmt->execute();
    $myJobsResult = $stmt->get_result();

    $myJobs = [];
    while ($row = $myJobsResult->fetch_assoc()) {
        $myJobs[] = $row;
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'new_jobs' => $newJobs,
        'my_jobs' => $myJobs,
        'total_new' => count($newJobs),
        'total_my' => count($myJobs),
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Get vendor jobs error: " . $e->getMessage());
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
