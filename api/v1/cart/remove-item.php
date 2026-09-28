<?php
/**
 * DELETE /api/v1/cart/remove-item/:cart_item_id
 * Remove item from cart
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Method not allowed']));
}

require_once __DIR__ . '/../../config.php';
require_once __DIR__ . '/../../jwt-auth.php';
require_once __DIR__ . '/../../services/cart_service.php';
require_once __DIR__ . '/../../services/pricing_service.php';

try {
    $token = verifyJWTToken();
    $phone_number = $token['phone_number'];

    $cart_item_id = isset($_GET['id']) ? (int) $_GET['id'] : null;

    if (!$cart_item_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'cart_item_id required']));
    }

    // Get cart_id from cart_item
    $stmt = $pdo->prepare("SELECT cart_id FROM cart_items WHERE id = ?");
    $stmt->execute([$cart_item_id]);
    $item = $stmt->fetch();

    if (!$item) {
        http_response_code(404);
        die(json_encode(['success' => false, 'message' => 'Item not found']));
    }

    $cart_id = $item['cart_id'];

    // Initialize services
    $cart_service = new CartService($pdo, $phone_number);
    $cart_service->setCartId($cart_id);

    // Remove item
    $result = $cart_service->removeItem($cart_item_id);

    // Fetch updated cart
    $cart = $cart_service->getCart();

    // Calculate pricing
    $pricing_service = new PricingService($pdo);
    $pricing = $pricing_service->calculateCartPricing($cart_id);

    $response = [
        'success' => true,
        'message' => 'Item removed from cart',
        'cart_id' => $cart_id,
        'item_count' => $cart['item_count'] ?? 0,
        'items' => $cart['items'] ?? [],
        'pricing' => $pricing,
        'can_checkout' => ($cart['item_count'] ?? 0) > 0
    ];

    http_response_code(200);
    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Error removing item: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Error removing item']);
}
?>
