<?php
/**
 * POST /api/v1/checkout/init
 * Initialize checkout session - lock prices and reserve slot
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
require_once __DIR__ . '/../../services/checkout_service.php';

try {
    $token = verifyJWTToken();
    $user_id = $token['sub'];

    $input = json_decode(file_get_contents('php://input'), true);
    $cart_id = $input['cart_id'] ?? null;
    $service_location_id = $input['service_location_id'] ?? null;
    $scheduled_date = $input['scheduled_date'] ?? null;
    $time_slot_id = $input['time_slot_id'] ?? null;

    // Validate inputs
    if (!$cart_id || !$service_location_id || !$scheduled_date || !$time_slot_id) {
        http_response_code(400);
        die(json_encode([
            'success' => false,
            'message' => 'Missing required fields: cart_id, service_location_id, scheduled_date, time_slot_id'
        ]));
    }

    // Validate date format
    if (!strtotime($scheduled_date)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid date format (use YYYY-MM-DD)']));
    }

    // Validate date is not in past
    if (strtotime($scheduled_date) < strtotime(date('Y-m-d'))) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Cannot book for past dates']));
    }

    // Get cart
    $cart_service = new CartService($pdo, $user_id);
    $cart_service->setCartId($cart_id);
    $cart_data = $cart_service->getCart();

    if (empty($cart_data['items'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Cart is empty']));
    }

    // Validate cart owns to user
    $stmt = $pdo->prepare("SELECT user_id FROM carts WHERE cart_id = ?");
    $stmt->execute([$cart_id]);
    $cart = $stmt->fetch();

    if (!$cart || $cart['user_id'] !== $user_id) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'Unauthorized access to cart']));
    }

    // Calculate pricing with location
    $pricing_service = new PricingService($pdo);
    $pricing_details = $pricing_service->calculateCartPricing($cart_id, $service_location_id);

    // Initialize checkout
    $checkout_service = new CheckoutService($pdo, $user_id);
    $result = $checkout_service->initCheckout(
        $cart_id,
        $service_location_id,
        $scheduled_date,
        $time_slot_id,
        $pricing_details
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
