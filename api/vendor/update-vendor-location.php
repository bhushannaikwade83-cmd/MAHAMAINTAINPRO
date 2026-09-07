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

    if (!isset($data['request_id']) || !isset($data['vendor_id']) || !isset($data['latitude']) || !isset($data['longitude'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: request_id, vendor_id, latitude, longitude']);
        exit;
    }

    $stmt = $pdo->prepare("
        INSERT INTO vendor_live_locations (
            request_id, vendor_id, latitude, longitude,
            speed, accuracy, heading, device_info, battery_level
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");

    $stmt->execute([
        $data['request_id'],
        $data['vendor_id'],
        $data['latitude'],
        $data['longitude'],
        $data['speed'] ?? null,
        $data['accuracy'] ?? null,
        $data['heading'] ?? null,
        $data['device_info'] ?? '',
        $data['battery_level'] ?? null
    ]);

    // Also update vendor's current location
    $updateStmt = $pdo->prepare("
        UPDATE vendors
        SET current_latitude = ?, current_longitude = ?, last_location_update = NOW()
        WHERE id = ?
    ");
    $updateStmt->execute([$data['latitude'], $data['longitude'], $data['vendor_id']]);

    echo json_encode([
        'success' => true,
        'location_id' => $pdo->lastInsertId()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
