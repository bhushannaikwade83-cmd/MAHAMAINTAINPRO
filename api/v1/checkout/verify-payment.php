<?php
/**
 * POST /api/v1/checkout/verify-payment
 * Verify Razorpay payment and create booking
 * This is the most critical endpoint - must be called SERVER-TO-SERVER, never from client
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
    $razorpay_payment_id = $input['razorpay_payment_id'] ?? null;
    $razorpay_signature = $input['razorpay_signature'] ?? null;

    if (!$checkout_id || !$razorpay_payment_id || !$razorpay_signature) {
        http_response_code(400);
        die(json_encode([
            'success' => false,
            'message' => 'Missing required fields: checkout_id, razorpay_payment_id, razorpay_signature'
        ]));
    }

    // Get Razorpay credentials
    $razorpay_key = RAZORPAY_KEY_ID ?? null;
    $razorpay_secret = RAZORPAY_KEY_SECRET ?? null;

    if (!$razorpay_key || !$razorpay_secret) {
        http_response_code(500);
        die(json_encode(['success' => false, 'message' => 'Payment gateway not configured']));
    }

    // Verify payment and create booking
    $checkout_service = new CheckoutService($pdo, $user_id);
    $result = $checkout_service->verifyAndCreateBooking(
        $checkout_id,
        $razorpay_payment_id,
        $razorpay_signature,
        $razorpay_key,
        $razorpay_secret
    );

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
