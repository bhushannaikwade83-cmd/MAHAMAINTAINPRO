<?php
/**
 * POST /api/v1/coupon/remove
 * Remove coupon from cart and recalculate pricing
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
require_once __DIR__ . '/../../services/pricing_service.php';

try {
    $token = verifyJWTToken();
    $user_id = $token['sub'];

    $input = json_decode(file_get_contents('php://input'), true);
    $cart_id = $input['cart_id'] ?? null;

    if (!$cart_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'cart_id required']));
    }

    // Verify cart ownership
    $stmt = $pdo->prepare("SELECT coupon_id FROM carts WHERE cart_id = ? AND user_id = ?");
    $stmt->execute([$cart_id, $user_id]);
    $cart = $stmt->fetch();

    if (!$cart) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'Unauthorized']));
    }

    if (!$cart['coupon_id']) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'No coupon applied to cart']));
    }

    // Remove coupon from cart
    $stmt = $pdo->prepare("UPDATE carts SET coupon_id = NULL, updated_at = NOW() WHERE cart_id = ?");
    $stmt->execute([$cart_id]);

    // Recalculate pricing without coupon
    $pricing_service = new PricingService($pdo);
    $pricing = $pricing_service->calculateCartPricing($cart_id, null);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Coupon removed',
        'pricing' => $pricing
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
