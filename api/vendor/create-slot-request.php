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

    if (!isset($data['customer_id']) || !isset($data['service_id']) || !isset($data['time_slot_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: customer_id, service_id, time_slot_id']);
        exit;
    }

    $pdo->beginTransaction();

    // Get slot details
    $slotStmt = $pdo->prepare("
        SELECT availability_date, slot_start_time, slot_end_time,
               service_category_id, base_price
        FROM service_time_slots
        WHERE id = ?
    ");
    $slotStmt->execute([$data['time_slot_id']]);
    $slot = $slotStmt->fetch(PDO::FETCH_ASSOC);

    if (!$slot) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Slot not found']);
        exit;
    }

    // Create service request
    $stmt = $pdo->prepare("
        INSERT INTO service_requests (
            customer_id, service_id, service_category_id, pincode,
            location_address, latitude, longitude, booking_type,
            scheduled_date, scheduled_time, time_slot_id,
            description, budget, status, payment_status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'SLOT', ?, ?, ?, ?, ?, 'PENDING', 'PENDING')
    ");

    $stmt->execute([
        $data['customer_id'],
        $data['service_id'],
        $slot['service_category_id'],
        $data['pincode'] ?? '',
        $data['location_address'] ?? '',
        $data['latitude'] ?? null,
        $data['longitude'] ?? null,
        $slot['availability_date'],
        $slot['slot_start_time'],
        $data['time_slot_id'],
        $data['description'] ?? '',
        $slot['base_price']
    ]);

    $request_id = $pdo->lastInsertId();

    // Update slot booking count
    $updateStmt = $pdo->prepare("
        UPDATE service_time_slots
        SET current_bookings = current_bookings + 1
        WHERE id = ?
    ");
    $updateStmt->execute([$data['time_slot_id']]);

    $pdo->commit();

    echo json_encode([
        'success' => true,
        'request_id' => $request_id,
        'status' => 'PENDING',
        'scheduled_date' => $slot['availability_date'],
        'scheduled_time' => $slot['slot_start_time'],
        'price' => (float)$slot['base_price']
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
