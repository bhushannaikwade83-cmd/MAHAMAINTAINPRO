<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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
    $input = json_decode(file_get_contents('php://input'), true);

    $vendor_id = isset($input['vendor_id']) ? intval($input['vendor_id']) : null;
    $category_ids = isset($input['category_ids']) ? (array)$input['category_ids'] : [];

    if (!$vendor_id) {
        throw new Exception('Vendor ID required');
    }

    if (empty($category_ids)) {
        throw new Exception('At least one category must be selected');
    }

    // Delete existing categories for this vendor
    $deleteQuery = "DELETE FROM vendor_service_categories WHERE vendor_id = ?";
    $deleteStmt = $conn->prepare($deleteQuery);
    $deleteStmt->bind_param("i", $vendor_id);
    $deleteStmt->execute();
    $deleteStmt->close();

    // Insert new categories
    $insertQuery = "INSERT INTO vendor_service_categories (vendor_id, category_id) VALUES (?, ?)";
    $insertStmt = $conn->prepare($insertQuery);

    foreach ($category_ids as $category_id) {
        $catId = intval($category_id);
        $insertStmt->bind_param("ii", $vendor_id, $catId);
        $insertStmt->execute();
    }
    $insertStmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Service categories saved successfully',
        'vendor_id' => $vendor_id,
        'categories_saved' => count($category_ids)
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Save vendor categories error: " . $e->getMessage());
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

$conn->close();
?>
