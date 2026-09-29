<?php
/**
 * POST /api/v1/bookings/cancel
 * Cancel booking and initiate refund
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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

    $input = json_decode(file_get_contents('php://input'), true);
    $booking_id = $input['booking_id'] ?? null;
    $reason = $input['reason'] ?? null;

    if (!$booking_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'booking_id required']));
    }

    $cancellation_service = new CancellationService($pdo);

    // Get cancellation policy first
    $policy = $cancellation_service->getCancellationPolicy($booking_id);

    if (!$policy['success']) {
        http_response_code(400);
        die(json_encode($policy));
    }

    // Check if refund would be 0
    if ($policy['refund_percent'] === 0) {
        http_response_code(400);
        die(json_encode([
            'success' => false,
            'message' => 'Cannot cancel: Booking is within 2 hours of scheduled time. No refund eligible.',
            'policy' => $policy
        ]));
    }

    // Cancel booking
    $result = $cancellation_service->cancelBooking($booking_id, $user_id, $reason);

    http_response_code(200);
    echo json_encode($result);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
