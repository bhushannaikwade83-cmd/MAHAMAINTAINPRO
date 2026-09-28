<?php
/**
 * POST /api/v1/cart/add-item
 * Add service to cart with package and addons
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
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

    // Parse request body
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid JSON input']));
    }

    // Validate required fields
    if (empty($input['service_id'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'service_id is required']));
    }

    $service_id = (int) $input['service_id'];
    $package_id = isset($input['package_id']) ? (int) $input['package_id'] : null;
    $quantity = isset($input['quantity']) ? (int) $input['quantity'] : 1;
    $selected_addons = isset($input['selected_addons']) ? (array) $input['selected_addons'] : [];
    $options = isset($input['options']) ? (array) $input['options'] : null;
    $provider_id = isset($input['provider_id']) ? (int) $input['provider_id'] : null;

    // Validate quantity
    if ($quantity < 1 || $quantity > 10) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Quantity must be between 1 and 10']));
    }

    // Initialize cart service
    $cart_service = new CartService($pdo, $phone_number);

    // Get or create cart
    $cart_id = $cart_service->initCart();
    $cart_service->setCartId($cart_id);

    // Add item to cart
    $result = $cart_service->addItem($service_id, $package_id, $quantity, $selected_addons, $options, $provider_id);

    if (!$result['success']) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Failed to add item to cart']));
    }

    // Fetch updated cart
    $cart = $cart_service->getCart();

    // Calculate pricing
    $pricing_service = new PricingService($pdo);
    $pricing = $pricing_service->calculateCartPricing($cart_id);

    // Return updated cart
    $response = [
        'success' => true,
        'message' => 'Item added to cart',
        'cart_id' => $cart_id,
        'cart_item_id' => $result['cart_item_id'],
        'item_count' => $cart['item_count'] ?? 0,
        'items' => $cart['items'] ?? [],
        'pricing' => $pricing,
        'can_checkout' => ($cart['item_count'] ?? 0) > 0
    ];

    http_response_code(200);
    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Error adding item to cart: " . $e->getMessage());
    echo json_encode([
        'success' => false,
        'message' => 'Error adding item to cart',
        'error' => $e->getMessage()
    ]);
}
?>
