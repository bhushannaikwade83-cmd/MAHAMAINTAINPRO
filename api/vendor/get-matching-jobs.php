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
    $vendor_id = isset($_GET['vendor_id']) ? intval($_GET['vendor_id']) : null;

    if (!$vendor_id) {
        throw new Exception('Vendor ID required');
    }

    // Get vendor's service categories
    $categoryQuery = "SELECT category_id FROM vendor_service_categories WHERE vendor_id = ?";
    $categoryStmt = $conn->prepare($categoryQuery);
    $categoryStmt->bind_param("i", $vendor_id);
    $categoryStmt->execute();
    $categoryResult = $categoryStmt->get_result();
    $vendorCategories = [];
    while ($row = $categoryResult->fetch_assoc()) {
        $vendorCategories[] = $row['category_id'];
    }
    $categoryStmt->close();

    // Get vendor's service pincodes
    $pincodeQuery = "SELECT pincode FROM vendor_pincodes WHERE vendor_id = ?";
    $pincodeStmt = $conn->prepare($pincodeQuery);
    $pincodeStmt->bind_param("i", $vendor_id);
    $pincodeStmt->execute();
    $pincodeResult = $pincodeStmt->get_result();
    $vendorPincodes = [];
    while ($row = $pincodeResult->fetch_assoc()) {
        $vendorPincodes[] = $row['pincode'];
    }
    $pincodeStmt->close();

    if (empty($vendorCategories) || empty($vendorPincodes)) {
        echo json_encode([
            'success' => true,
            'jobs' => [],
            'message' => 'Vendor has no service categories or pincodes configured'
        ]);
        exit();
    }

    // Build placeholders for IN clause
    $categoryPlaceholders = implode(',', array_fill(0, count($vendorCategories), '?'));
    $pincodePlaceholders = implode(',', array_fill(0, count($vendorPincodes), '?'));

    // Fetch matching orders
    $jobQuery = "SELECT
        o.id,
        o.order_id,
        o.phone_number,
        o.address_id,
        o.pincode,
        o.total_amount,
        o.service_count,
        o.scheduled_at,
        o.created_at,
        GROUP_CONCAT(oi.service_name SEPARATOR ', ') as service_names,
        GROUP_CONCAT(oi.category SEPARATOR ', ') as categories,
        GROUP_CONCAT(oi.price SEPARATOR ', ') as prices,
        a.full_address,
        a.city,
        a.society_name
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN addresses a ON o.address_id = a.id
    WHERE o.order_status IN ('pending', 'requested')
    AND o.pincode IN ($pincodePlaceholders)
    AND oi.category IN ($categoryPlaceholders)
    GROUP BY o.order_id
    ORDER BY o.created_at DESC
    LIMIT 50";

    $jobStmt = $conn->prepare($jobQuery);

    // Bind pincode parameters
    $types = str_repeat('s', count($vendorPincodes));
    $params = $vendorPincodes;

    // Bind category parameters
    $types .= str_repeat('s', count($vendorCategories));
    $params = array_merge($params, $vendorCategories);

    // Bind all parameters
    $jobStmt->bind_param($types, ...$params);
    $jobStmt->execute();
    $jobResult = $jobStmt->get_result();

    $jobs = [];
    while ($row = $jobResult->fetch_assoc()) {
        $jobs[] = [
            'id' => (int)$row['id'],
            'order_id' => $row['order_id'],
            'phone_number' => $row['phone_number'],
            'pincode' => $row['pincode'],
            'address' => $row['full_address'] ?? $row['society_name'] ?? 'N/A',
            'city' => $row['city'] ?? 'N/A',
            'service_names' => $row['service_names'],
            'categories' => $row['categories'],
            'amount' => (float)$row['total_amount'],
            'service_count' => (int)$row['service_count'],
            'scheduled_at' => $row['scheduled_at'],
            'created_at' => $row['created_at'],
            'status' => 'available'
        ];
    }
    $jobStmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'jobs' => $jobs,
        'count' => count($jobs)
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Get matching jobs error: " . $e->getMessage());
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

$conn->close();
?>
