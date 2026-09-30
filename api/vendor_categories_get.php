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
    echo json_encode(['success' => false, 'error' => 'Database connection failed']);
    exit();
}

try {
    $vendor_id = isset($_GET['vendor_id']) ? intval($_GET['vendor_id']) : null;

    if (!$vendor_id) {
        throw new Exception('Vendor ID required');
    }

    $query = "SELECT category_id FROM vendor_service_categories WHERE vendor_id = ? ORDER BY category_id ASC";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $vendor_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $category_ids = [];
    while ($row = $result->fetch_assoc()) {
        $category_ids[] = (int)$row['category_id'];
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'category_ids' => $category_ids,
        'count' => count($category_ids)
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Get vendor categories error: " . $e->getMessage());
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

$conn->close();
?>
