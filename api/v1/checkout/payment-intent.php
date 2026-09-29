<?php
/**
 * POST /api/v1/checkout/payment-intent
 * Create Razorpay payment order
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
require_once __DIR__ . '/../../services/checkout_service.php';

try {
    $token = verifyJWTToken();
    $user_id = $token['sub'];

    $input = json_decode(file_get_contents('php://input'), true);
    $checkout_id = $input['checkout_id'] ?? null;

    if (!$checkout_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'checkout_id required']));
    }

    // Get Razorpay credentials from config
    $razorpay_key = RAZORPAY_KEY_ID ?? null;
    $razorpay_secret = RAZORPAY_KEY_SECRET ?? null;

    if (!$razorpay_key || !$razorpay_secret) {
        http_response_code(500);
        die(json_encode(['success' => false, 'message' => 'Payment gateway not configured']));
    }

    // Get checkout details
    $checkout_service = new CheckoutService($pdo, $user_id);
    $checkout = $checkout_service->getCheckoutStatus($checkout_id);

    if (!$checkout) {
        http_response_code(404);
        die(json_encode(['success' => false, 'message' => 'Checkout session not found']));
    }

    // Verify checkout belongs to user
    if ($checkout['user_id'] !== $user_id) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'Unauthorized']));
    }

    // Verify checkout is still valid
    if (strtotime($checkout['expires_at']) < time()) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Checkout session expired']));
    }

    // Create Razorpay payment order
    $pricing = json_decode($checkout['pricing_snapshot'], true);
    $amount = $pricing['total'] ?? 0;

    $result = $checkout_service->createPaymentIntent($checkout_id, $amount, $razorpay_key, $razorpay_secret);

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
