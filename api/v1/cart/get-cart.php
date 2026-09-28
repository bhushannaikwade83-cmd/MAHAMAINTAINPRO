<?php
/**
 * GET /api/v1/cart
 * Fetch complete cart for authenticated user
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Method not allowed']));
}

require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../jwt-auth.php';
require_once __DIR__ . '/../../services/cart_service.php';
require_once __DIR__ . '/../../services/pricing_service.php';

try {
    // Verify JWT token
    $token = verifyJWTToken();
    $phone_number = $token['phone_number'];

    if (!$phone_number) {
        http_response_code(401);
        die(json_encode(['success' => false, 'message' => 'Phone number not in token']));
    }

    // Initialize cart service
    $cart_service = new CartService($pdo, $phone_number);

    // Get active cart or create new one
    $cart_id = $cart_service->initCart();
    $cart_service->setCartId($cart_id);

    // Fetch cart
    $cart = $cart_service->getCart();

    // Calculate pricing
    $pricing_service = new PricingService($pdo);
    $pricing = $pricing_service->calculateCartPricing(
        $cart_id,
        $cart['service_location_id'],
        $cart['coupon_id']
    );

    // Combine response
    $response = [
        'success' => true,
        'cart_id' => $cart_id,
        'user_id' => $phone_number,
        'item_count' => $cart['item_count'] ?? 0,
        'items' => $cart['items'] ?? [],
        'pricing' => $pricing,
        'scheduled_date' => $cart['scheduled_date'],
        'scheduled_time_slot' => $cart['scheduled_time_slot'],
        'service_location_id' => $cart['service_location_id'],
        'coupon_code' => $cart['coupon_code'],
        'can_checkout' => ($cart['item_count'] ?? 0) > 0,
        'created_at' => $cart['created_at'],
        'updated_at' => $cart['updated_at']
    ];

    http_response_code(200);
    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error fetching cart',
        'error' => $e->getMessage()
    ]);
}
?>
