<?php
/**
 * POST /api/v1/coupon/validate
 * Validate coupon eligibility
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
    $input = json_decode(file_get_contents('php://input'), true);
    $coupon_code = $input['coupon_code'] ?? null;
    $cart_value = $input['cart_value'] ?? 0;

    if (!$coupon_code) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'coupon_code required']));
    }

    // Get coupon
    $stmt = $pdo->prepare("SELECT * FROM coupons WHERE UPPER(code) = UPPER(?) LIMIT 1");
    $stmt->execute([$coupon_code]);
    $coupon = $stmt->fetch();

    if (!$coupon) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Coupon not found']));
    }

    // Validate
    $pricing_service = new PricingService($pdo);
    $result = $pricing_service->validateAndApplyCoupon($coupon['id'], $cart_value);

    http_response_code($result['valid'] ? 200 : 400);
    echo json_encode($result);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error validating coupon']);
}
?>
