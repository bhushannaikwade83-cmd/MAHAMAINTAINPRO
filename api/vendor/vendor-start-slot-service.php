<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['request_id']) || !isset($data['vendor_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: request_id, vendor_id']);
        exit;
    }

    // Update request status to EN_ROUTE
    $stmt = $pdo->prepare("
        UPDATE service_requests
        SET status = 'EN_ROUTE',
            started_at = NOW()
        WHERE id = ? AND assigned_vendor_id = ? AND booking_type = 'SLOT'
    ");

    $stmt->execute([$data['request_id'], $data['vendor_id']]);

    if ($stmt->rowCount() === 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Request not found or not assigned to this vendor']);
        exit;
    }

    echo json_encode([
        'success' => true,
        'request_id' => $data['request_id'],
        'status' => 'EN_ROUTE',
        'location_tracking_started' => true
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
