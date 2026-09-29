<?php
/**
 * GET /api/v1/locations/check
 * Check if service is available at location
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
require_once __DIR__ . '/../../services/location_service.php';

try {
    $token = verifyJWTToken();

    $service_id = $_GET['service_id'] ?? null;
    $location_id = $_GET['location_id'] ?? null;
    $pincode = $_GET['pincode'] ?? null;

    if (!$service_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'service_id required']));
    }

    $location_service = new LocationService($pdo);

    // Check by pincode if provided
    if ($pincode) {
        $result = $location_service->isServiceableByPincode($service_id, $pincode);
        http_response_code($result['serviceable'] ? 200 : 400);
        echo json_encode([
            'success' => $result['serviceable'],
            'service_id' => $service_id,
            'pincode' => $pincode,
            'serviceable' => $result['serviceable'],
            'details' => $result
        ]);
        exit();
    }

    // Check by location_id
    if (!$location_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Either location_id or pincode required']));
    }

    $result = $location_service->isServiceable($service_id, $location_id);

    http_response_code($result['serviceable'] ? 200 : 400);
    echo json_encode([
        'success' => $result['serviceable'],
        'service_id' => $service_id,
        'location_id' => $location_id,
        'serviceable' => $result['serviceable'],
        'travel_fee' => $result['travel_fee'] ?? null,
        'tax_rate' => $result['tax_rate'] ?? null,
        'available_hours' => [
            'from' => $result['available_from'] ?? null,
            'to' => $result['available_until'] ?? null
        ],
        'message' => $result['reason'] ?? 'Service available'
    ]);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
