<?php
/**
 * POST /api/v1/coupon/apply
 * Apply coupon to cart and recalculate pricing
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
require_once __DIR__ . '/../../services/cart_service.php';
require_once __DIR__ . '/../../services/pricing_service.php';

try {
    $token = verifyJWTToken();
    $user_id = $token['sub'];

    $input = json_decode(file_get_contents('php://input'), true);
    $cart_id = $input['cart_id'] ?? null;
    $coupon_code = $input['coupon_code'] ?? null;

    if (!$cart_id || !$coupon_code) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'cart_id and coupon_code required']));
    }

    // Verify cart ownership
    $stmt = $pdo->prepare("SELECT user_id FROM carts WHERE cart_id = ?");
    $stmt->execute([$cart_id]);
    $cart = $stmt->fetch();

    if (!$cart || $cart['user_id'] !== $user_id) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'Unauthorized']));
    }

    // Get coupon
    $stmt = $pdo->prepare("SELECT * FROM coupons WHERE UPPER(code) = UPPER(?) AND is_active = 1 LIMIT 1");
    $stmt->execute([$coupon_code]);
    $coupon = $stmt->fetch();

    if (!$coupon) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Coupon not found or inactive']));
    }

    // Validate coupon dates
    if (strtotime($coupon['valid_from']) > time()) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Coupon not yet valid']));
    }

    if (strtotime($coupon['valid_until']) < time()) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Coupon expired']));
    }

    // Check usage limit
    if ($coupon['usage_limit'] && $coupon['usage_count'] >= $coupon['usage_limit']) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Coupon usage limit reached']));
    }

    // Check first order only
    if ($coupon['is_first_order_only']) {
        $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM bookings WHERE user_id = ? AND status = 'confirmed'");
        $stmt->execute([$user_id]);
        $result = $stmt->fetch();
        if ($result['count'] > 0) {
            http_response_code(400);
            die(json_encode(['success' => false, 'message' => 'Coupon only valid for first order']));
        }
    }

    // Get cart items total
    $stmt = $pdo->prepare("SELECT SUM(item_subtotal) as total FROM cart_items WHERE cart_id = ?");
    $stmt->execute([$cart_id]);
    $result = $stmt->fetch();
    $cart_value = $result['total'] ?? 0;

    // Check minimum amount
    if ($cart_value < $coupon['min_amount']) {
        http_response_code(400);
        die(json_encode([
            'success' => false,
            'message' => 'Minimum order value of ₹' . $coupon['min_amount'] . ' required'
        ]));
    }

    // Apply coupon to cart
    $stmt = $pdo->prepare("UPDATE carts SET coupon_id = ?, updated_at = NOW() WHERE cart_id = ?");
    $stmt->execute([$coupon['id'], $cart_id]);

    // Calculate new pricing
    $pricing_service = new PricingService($pdo);
    $pricing = $pricing_service->calculateCartPricing($cart_id, null, $coupon['id']);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Coupon applied successfully',
        'coupon' => [
            'code' => $coupon['code'],
            'discount_type' => $coupon['discount_type'],
            'discount_value' => $coupon['discount_value'],
            'discount_amount' => $pricing['discount_amount']
        ],
        'pricing' => $pricing
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
