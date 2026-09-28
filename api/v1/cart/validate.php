<?php
/**
 * POST /api/v1/cart/validate
 * Validate entire cart before checkout
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
    $phone_number = $token['phone_number'];

    $input = json_decode(file_get_contents('php://input'), true);
    $cart_id = $input['cart_id'] ?? null;
    $service_location_id = $input['service_location_id'] ?? null;
    $scheduled_date = $input['scheduled_date'] ?? null;
    $time_slot_id = $input['time_slot_id'] ?? null;

    if (!$cart_id) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'cart_id required']));
    }

    $issues = [];

    // Check if cart has items
    $stmt = $pdo->prepare("SELECT COUNT(*) as item_count FROM cart_items WHERE cart_id = ?");
    $stmt->execute([$cart_id]);
    $cart_data = $stmt->fetch();

    if ($cart_data['item_count'] == 0) {
        $issues[] = [
            'type' => 'EMPTY_CART',
            'message' => 'Cart is empty'
        ];
    }

    // Check if location is provided
    if (!$service_location_id) {
        $issues[] = [
            'type' => 'LOCATION_REQUIRED',
            'message' => 'Service location must be selected'
        ];
    }

    // Check if date is provided
    if (!$scheduled_date) {
        $issues[] = [
            'type' => 'DATE_REQUIRED',
            'message' => 'Service date must be selected'
        ];
    }

    // Check if slot is provided
    if (!$time_slot_id) {
        $issues[] = [
            'type' => 'SLOT_REQUIRED',
            'message' => 'Time slot must be selected'
        ];
    }

    // Validate slot availability if all required fields present
    if ($time_slot_id && $scheduled_date) {
        $stmt = $pdo->prepare(
            "SELECT is_available, booked_count, total_capacity
             FROM time_slot_availability
             WHERE slot_id = ? AND service_date = ?"
        );
        $stmt->execute([$time_slot_id, $scheduled_date]);
        $slot = $stmt->fetch();

        if (!$slot || !$slot['is_available']) {
            $issues[] = [
                'type' => 'SLOT_UNAVAILABLE',
                'message' => 'Selected time slot is no longer available'
            ];
        } elseif ($slot['booked_count'] >= $slot['total_capacity']) {
            $issues[] = [
                'type' => 'SLOT_FULLY_BOOKED',
                'message' => 'Selected time slot is fully booked'
            ];
        }
    }

    // Check minimum booking value
    $pricing_service = new PricingService($pdo);
    $pricing = $pricing_service->calculateCartPricing($cart_id, $service_location_id);

    $stmt = $pdo->prepare(
        "SELECT MIN(min_booking_value) as min_value
         FROM services s
         JOIN cart_items ci ON s.id = ci.service_id
         WHERE ci.cart_id = ? AND s.min_booking_value > 0"
    );
    $stmt->execute([$cart_id]);
    $min_data = $stmt->fetch();

    if ($min_data && $min_data['min_value'] > 0) {
        if ($pricing['total'] < $min_data['min_value']) {
            $issues[] = [
                'type' => 'MINIMUM_VALUE_NOT_MET',
                'message' => "Minimum booking value is ₹{$min_data['min_value']}. Add ₹" .
                           number_format($min_data['min_value'] - $pricing['total'], 2) . " more."
            ];
        }
    }

    $response = [
        'success' => count($issues) === 0,
        'valid' => count($issues) === 0,
        'issues' => $issues,
        'pricing' => $pricing,
        'message' => count($issues) === 0 ? 'Cart is valid' : 'Cart validation failed'
    ];

    http_response_code(200);
    echo json_encode($response);

} catch (Exception $e) {
    http_response_code(500);
    error_log("Error validating cart: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Error validating cart']);
}
?>
