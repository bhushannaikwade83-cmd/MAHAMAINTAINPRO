<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['customer_id']) || !isset($data['service_id']) || !isset($data['pincode'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: customer_id, service_id, pincode']);
        exit;
    }

    $stmt = $pdo->prepare("
        INSERT INTO service_requests (
            customer_id, service_id, service_category_id, pincode,
            location_address, latitude, longitude, booking_type,
            description, budget, status, payment_status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'INSTANT', ?, ?, 'PENDING', 'PENDING')
    ");

    $stmt->execute([
        $data['customer_id'], $data['service_id'], $data['service_category_id'] ?? 1,
        $data['pincode'], $data['location_address'] ?? '', $data['latitude'] ?? null,
        $data['longitude'] ?? null, $data['description'] ?? '', $data['budget'] ?? 0
    ]);

    echo json_encode([
        'success' => true,
        'request_id' => $pdo->lastInsertId(),
        'status' => 'PENDING'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
