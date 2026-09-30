<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);

$logfile = '/tmp/get-matching-jobs.log';
error_log("=== Request at " . date('Y-m-d H:i:s') . " ===", 3, $logfile);
error_log("Method: " . $_SERVER['REQUEST_METHOD'], 3, $logfile);
error_log("Query: " . json_encode($_GET), 3, $logfile);

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
    echo json_encode(['success' => false, 'error' => 'DB: ' . $conn->connect_error]);
    exit();
}

// DEBUG: Check addresses table schema
$schema = $conn->query("DESCRIBE addresses");
$columns = [];
if ($schema) {
    while ($col = $schema->fetch_assoc()) {
        $columns[] = $col['Field'];
    }
}

try {
    $vendor_id = isset($_GET['vendor_id']) ? intval($_GET['vendor_id']) : null;
    error_log("Vendor ID: $vendor_id", 3, $logfile);

    if (!$vendor_id) {
        throw new Exception('Vendor ID required');
    }

    // Get vendor's service categories (as IDs for matching with order_items)
    $categoryQuery = "SELECT category_id FROM vendor_service_categories WHERE vendor_id = ?";
    $categoryStmt = $conn->prepare($categoryQuery);
    if (!$categoryStmt) {
        throw new Exception("Category query prepare failed: " . $conn->error);
    }
    $categoryStmt->bind_param("i", $vendor_id);
    $categoryStmt->execute();
    $categoryResult = $categoryStmt->get_result();
    $vendorCategories = [];
    while ($row = $categoryResult->fetch_assoc()) {
        $vendorCategories[] = (int)$row['category_id'];
    }
    $categoryStmt->close();
    error_log("Vendor categories: " . json_encode($vendorCategories), 3, $logfile);

    // Get vendor's service pincodes
    $pincodeQuery = "SELECT pincode FROM vendor_pincodes WHERE vendor_id = ?";
    $pincodeStmt = $conn->prepare($pincodeQuery);
    if (!$pincodeStmt) {
        throw new Exception("Pincode query prepare failed: " . $conn->error);
    }
    $pincodeStmt->bind_param("i", $vendor_id);
    $pincodeStmt->execute();
    $pincodeResult = $pincodeStmt->get_result();
    $vendorPincodes = [];
    while ($row = $pincodeResult->fetch_assoc()) {
        $vendorPincodes[] = $row['pincode'];
    }
    $pincodeStmt->close();
    error_log("Vendor pincodes: " . json_encode($vendorPincodes), 3, $logfile);

    if (empty($vendorPincodes)) {
        error_log("No pincodes - returning empty jobs", 3, $logfile);
        echo json_encode([
            'success' => true,
            'jobs' => [],
            'message' => 'Vendor has no pincodes configured. Add pincodes in "My Shop Pincodes"'
        ]);
        exit();
    }

    // Build placeholders for pincode IN clause
    $pincodePlaceholders = implode(',', array_fill(0, count($vendorPincodes), '?'));

    // If vendor has categories, filter by them; otherwise show all orders for their pincodes
    if (!empty($vendorCategories)) {
        $categoryPlaceholders = implode(',', array_fill(0, count($vendorCategories), '?'));
        $jobQuery = "SELECT
            o.id, o.order_id, o.phone_number, o.address_id, o.pincode, o.total_amount,
            o.service_count, o.scheduled_at, o.created_at,
            o.before_photo_url, o.after_photo_url, o.payment_screenshot_url, o.customer_signature_url,
            GROUP_CONCAT(oi.service_name SEPARATOR ', ') as service_names,
            GROUP_CONCAT(oi.category SEPARATOR ', ') as categories,
            a.full_address
        FROM orders o
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        LEFT JOIN addresses a ON o.address_id = a.id
        WHERE o.order_status IN ('pending', 'requested')
        AND o.pincode IN ($pincodePlaceholders)
        AND oi.category IN ($categoryPlaceholders)
        GROUP BY o.order_id
        ORDER BY o.created_at DESC LIMIT 50";

        $jobStmt = $conn->prepare($jobQuery);
        if (!$jobStmt) {
            throw new Exception("Job query prepare failed (with categories): " . $conn->error);
        }
        $types = str_repeat('s', count($vendorPincodes)) . str_repeat('i', count($vendorCategories));
        $params = array_merge($vendorPincodes, $vendorCategories);
        $jobStmt->bind_param($types, ...$params);
    } else {
        // No categories - show all orders for vendor's pincodes
        $jobQuery = "SELECT
            o.id, o.order_id, o.phone_number, o.address_id, o.pincode, o.total_amount,
            o.service_count, o.scheduled_at, o.created_at,
            o.before_photo_url, o.after_photo_url, o.payment_screenshot_url, o.customer_signature_url,
            GROUP_CONCAT(oi.service_name SEPARATOR ', ') as service_names,
            GROUP_CONCAT(oi.category SEPARATOR ', ') as categories,
            a.full_address
        FROM orders o
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        LEFT JOIN addresses a ON o.address_id = a.id
        WHERE o.order_status IN ('pending', 'requested')
        AND o.pincode IN ($pincodePlaceholders)
        GROUP BY o.order_id
        ORDER BY o.created_at DESC LIMIT 50";

        $jobStmt = $conn->prepare($jobQuery);
        if (!$jobStmt) {
            throw new Exception("Job query prepare failed (no categories): " . $conn->error);
        }
        $types = str_repeat('s', count($vendorPincodes));
        $params = $vendorPincodes;
        $jobStmt->bind_param($types, ...$params);
    }

    $jobStmt->execute();
    $jobResult = $jobStmt->get_result();
    error_log("Query executed. Rows found: " . $jobResult->num_rows, 3, $logfile);

    $jobs = [];
    while ($row = $jobResult->fetch_assoc()) {
        try {
            $createdAt = new DateTime($row['created_at'] ?? 'now');
            $expiresAt = (clone $createdAt)->modify('+10 minutes');
        } catch (Exception $dateEx) {
            $createdAt = new DateTime('now');
            $expiresAt = (clone $createdAt)->modify('+10 minutes');
        }

        $jobs[] = [
            'id' => (int)$row['id'],
            'customer_name' => 'Customer Order',
            'customer_phone' => $row['phone_number'],
            'service_name' => $row['service_names'],
            'service_category_id' => 1,
            'location_address' => $row['full_address'] ?? 'N/A',
            'pincode' => $row['pincode'],
            'budget' => (int)$row['total_amount'],
            'amount' => (int)$row['total_amount'],
            'scheduled_date' => $row['scheduled_at'] ? date('Y-m-d', strtotime($row['scheduled_at'])) : null,
            'scheduled_time' => $row['scheduled_at'] ? date('H:i', strtotime($row['scheduled_at'])) : null,
            'booking_type' => $row['scheduled_at'] ? 'slot' : 'instant',
            'customer_id' => 0,
            'created_at' => $row['created_at'],
            'expires_at' => $expiresAt->format('Y-m-d H:i:s'),
            'description' => $row['service_names'],
            'status' => 'pending',
            'order_id' => $row['order_id'],
            'service_count' => (int)$row['service_count']
        ];
    }
    $jobStmt->close();

    // Convert relative photo URLs to absolute
    function makeAbsoluteUrl($url) {
        if (empty($url)) return null;
        if (strpos($url, 'https://') === 0 || strpos($url, 'http://') === 0) {
            return $url;
        }
        return 'https://' . $_SERVER['HTTP_HOST'] . $url;
    }

    foreach ($jobs as &$job) {
        if (isset($job['before_photo_url'])) {
            $job['before_photo_url'] = makeAbsoluteUrl($job['before_photo_url']);
        }
        if (isset($job['after_photo_url'])) {
            $job['after_photo_url'] = makeAbsoluteUrl($job['after_photo_url']);
        }
        if (isset($job['payment_screenshot_url'])) {
            $job['payment_screenshot_url'] = makeAbsoluteUrl($job['payment_screenshot_url']);
        }
        if (isset($job['customer_signature_url'])) {
            $job['customer_signature_url'] = makeAbsoluteUrl($job['customer_signature_url']);
        }
    }

    http_response_code(200);
    error_log("Success! Returning " . count($jobs) . " jobs", 3, $logfile);
    echo json_encode([
        'success' => true,
        'jobs' => $jobs,
        'count' => count($jobs)
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Get matching jobs error: " . $e->getMessage(), 3, $logfile);
    error_log("Stack trace: " . $e->getTraceAsString(), 3, $logfile);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'debug_addresses_columns' => $columns ?? []
    ]);
}

$conn->close();
?>
