<?php
/**
 * GET /api/v1/slots/available
 * Get available time slots for a service on a specific date
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../jwt-auth.php';
require_once __DIR__ . '/../../services/slot_service.php';

try {
    $token = verifyJWTToken();

    $service_id = $_GET['service_id'] ?? null;
    $slot_date = $_GET['date'] ?? null;

    if (!$service_id || !$slot_date) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'service_id and date required']));
    }

    // Validate date format
    if (!strtotime($slot_date)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid date format (use YYYY-MM-DD)']));
    }

    $slot_service = new SlotService($pdo);
    $slots = $slot_service->getAvailableSlots($service_id, $slot_date);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'service_id' => $service_id,
        'date' => $slot_date,
        'slot_count' => count($slots),
        'slots' => $slots
    ]);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
