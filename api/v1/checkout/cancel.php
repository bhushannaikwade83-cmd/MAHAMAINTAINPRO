<?php
/**
 * POST /api/v1/checkout/cancel
 * Cancel checkout session and release slot reservation
 * Only works before payment is verified
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

    // Verify checkout exists and belongs to user
    $stmt = $pdo->prepare("SELECT * FROM checkout_sessions WHERE checkout_id = ? AND user_id = ?");
    $stmt->execute([$checkout_id, $user_id]);
    $checkout = $stmt->fetch();

    if (!$checkout) {
        http_response_code(404);
        die(json_encode(['success' => false, 'message' => 'Checkout not found']));
    }

    // Cancel checkout
    $checkout_service = new CheckoutService($pdo, $user_id);
    $result = $checkout_service->cancelCheckout($checkout_id);

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
