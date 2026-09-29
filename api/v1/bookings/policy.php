<?php
/**
 * GET /api/v1/bookings/policy
 * Get cancellation policy and potential refund amount
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
require_once __DIR__ . '/../../services/cancellation_service.php';

try {
    $token = verifyJWTToken();
    $user_id = $token['sub'];

    $booking_id = $_GET['booking_id'] ?? null;

    if (!$booking_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'booking_id required']));
    }

    // Verify booking belongs to user
    $stmt = $pdo->prepare("SELECT user_id FROM bookings WHERE booking_id = ?");
    $stmt->execute([$booking_id]);
    $booking = $stmt->fetch();

    if (!$booking || $booking['user_id'] !== $user_id) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'Unauthorized']));
    }

    $cancellation_service = new CancellationService($pdo);
    $policy = $cancellation_service->getCancellationPolicy($booking_id);

    http_response_code(200);
    echo json_encode($policy);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
