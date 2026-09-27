<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Public, read-only - the app's home screen "Offers" carousel.
try {
    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        throw new Exception('Database connection failed');
    }

    $result = $conn->query("SELECT id, title, image_path, link_type, link_value FROM banners WHERE is_active = 1 ORDER BY sort_order ASC, id DESC");
    $banners = [];
    while ($row = $result->fetch_assoc()) {
        $banners[] = $row;
    }

    echo json_encode(['success' => true, 'banners' => $banners, 'total' => count($banners)]);
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
