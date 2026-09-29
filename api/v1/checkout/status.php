<?php
/**
 * GET /api/v1/checkout/status
 * Get checkout status and booking details
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
require_once __DIR__ . '/../../services/checkout_service.php';

try {
    $token = verifyJWTToken();
    $user_id = $token['sub'];

    $checkout_id = $_GET['checkout_id'] ?? null;

    if (!$checkout_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'checkout_id required']));
    }

    $checkout_service = new CheckoutService($pdo, $user_id);
    $checkout = $checkout_service->getCheckoutStatus($checkout_id);

    if (!$checkout) {
        http_response_code(404);
        die(json_encode(['success' => false, 'message' => 'Checkout not found']));
    }

    // Verify ownership
    if ($checkout['user_id'] !== $user_id) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'Unauthorized']));
    }

    $response = [
        'success' => true,
        'checkout_id' => $checkout['checkout_id'],
        'status' => $checkout['status'],
        'cart_id' => $checkout['cart_id'],
        'scheduled_date' => $checkout['scheduled_date'],
        'payment_amount' => $checkout['payment_amount'],
        'created_at' => $checkout['created_at'],
        'expires_at' => $checkout['expires_at'],
        'is_expired' => strtotime($checkout['expires_at']) < time()
    ];

    // If payment verified, include booking/order details
    if ($checkout['status'] === 'payment_verified' && $checkout['booking_id']) {
        $stmt = $pdo->prepare("SELECT * FROM bookings WHERE booking_id = ?");
        $stmt->execute([$checkout['booking_id']]);
        $booking = $stmt->fetch();

        if ($booking) {
            $response['booking_id'] = $booking['booking_id'];
            $response['booking_status'] = $booking['status'];
            $response['payment_id'] = $booking['payment_id'];
        }
    }

    http_response_code(200);
    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
