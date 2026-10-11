<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $category_id = $_GET['category_id'] ?? null;
    $date = $_GET['date'] ?? date('Y-m-d');

    if (!$category_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'category_id required']);
        exit;
    }

    // Get available slots for the date
    $stmt = $pdo->prepare("
        SELECT id, slot_start_time, slot_end_time, slot_label,
               max_bookings, current_bookings, base_price,
               (max_bookings - current_bookings) as available_slots
        FROM service_time_slots
        WHERE service_category_id = ?
        AND availability_date = ?
        AND is_available = 1
        ORDER BY slot_start_time ASC
    ");

    $stmt->execute([$category_id, $date]);
    $slots = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'date' => $date,
        'slots' => array_map(function($slot) {
            return [
                'id' => (int)$slot['id'],
                'label' => $slot['slot_label'],
                'start_time' => $slot['slot_start_time'],
                'end_time' => $slot['slot_end_time'],
                'base_price' => (float)$slot['base_price'],
                'available_slots' => (int)$slot['available_slots'],
                'is_available' => (int)$slot['available_slots'] > 0 ? 1 : 0
            ];
        }, $slots),
        'total_slots' => count($slots)
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
