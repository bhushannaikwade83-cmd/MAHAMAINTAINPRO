<?php
/**
 * GET /api/v1/slots/dates
 * Get available dates for next 30 days
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
    $days_ahead = $_GET['days'] ?? 30;

    if (!$service_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'service_id required']));
    }

    // Validate days parameter
    $days_ahead = min(max((int)$days_ahead, 1), 90); // Between 1 and 90 days

    $slot_service = new SlotService($pdo);
    $dates = $slot_service->getAvailableDates($service_id, $days_ahead);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'service_id' => $service_id,
        'date_count' => count($dates),
        'available_dates' => $dates
    ]);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
