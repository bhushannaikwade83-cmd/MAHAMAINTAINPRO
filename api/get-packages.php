<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Public, read-only - packages shown to residents for booking.
try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $result = $conn->query("SELECT id, name, description, image_path, price FROM service_packages WHERE is_active = 1 ORDER BY id DESC");
    $packages = [];
    while ($row = $result->fetch_assoc()) {
        $itemStmt = $conn->prepare("SELECT s.id, s.name FROM service_package_items sp JOIN services s ON s.id = sp.service_id WHERE sp.package_id = ?");
        $itemStmt->bind_param('i', $row['id']);
        $itemStmt->execute();
        $itemsResult = $itemStmt->get_result();
        $items = [];
        while ($item = $itemsResult->fetch_assoc()) {
            $items[] = $item;
        }
        $itemStmt->close();
        $row['services'] = $items;
        $packages[] = $row;
    }

    echo json_encode(['success' => true, 'packages' => $packages, 'total' => count($packages)]);
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
