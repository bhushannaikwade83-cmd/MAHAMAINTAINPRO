<?php
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

try {
    $token = verifyJWTToken();
    $phone_number = $token['phone_number'];

    $input = json_decode(file_get_contents('php://input'), true);
    $cart_id = $input['cart_id'] ?? null;

    if (!$cart_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'cart_id required']));
    }

    $cart_service = new CartService($pdo, $phone_number);
    $cart_service->setCartId($cart_id);
    $cart_service->clearCart();

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Cart cleared']);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error clearing cart']);
}
?>
