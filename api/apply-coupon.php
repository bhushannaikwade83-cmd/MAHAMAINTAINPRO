<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        throw new Exception('Invalid input');
    }

    $code = trim(strtoupper($input['code'] ?? ''));
    $cartTotal = $input['cart_total'] ?? 0;

    if (!$code || $cartTotal <= 0) {
        throw new Exception('Coupon code and cart total required');
    }

    // Fetch coupon details
    $query = "SELECT id, code, description, discount_type, discount_value, min_amount, max_discount, usage_limit, usage_count
              FROM coupons
              WHERE code = ? AND is_active = 1
              AND (valid_until IS NULL OR valid_until > NOW())
              LIMIT 1";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param("s", $code);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid or expired coupon']);
        exit();
    }

    $coupon = $result->fetch_assoc();
    $stmt->close();

    // Validate coupon
    if ($coupon['usage_limit'] && $coupon['usage_count'] >= $coupon['usage_limit']) {
        throw new Exception('Coupon usage limit exceeded');
    }

    if ($cartTotal < $coupon['min_amount']) {
        throw new Exception('Cart total must be at least ₹' . $coupon['min_amount']);
    }

    // Calculate discount
    $discount = 0;
    if ($coupon['discount_type'] === 'percentage') {
        $discount = ($cartTotal * $coupon['discount_value']) / 100;
    } else {
        $discount = $coupon['discount_value'];
    }

    // Apply max discount limit if set
    if ($coupon['max_discount'] && $discount > $coupon['max_discount']) {
        $discount = $coupon['max_discount'];
    }

    $finalTotal = $cartTotal - $discount;

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'coupon_code' => $coupon['code'],
        'description' => $coupon['description'],
        'discount_type' => $coupon['discount_type'],
        'discount_value' => $coupon['discount_value'],
        'discount_amount' => round($discount, 2),
        'original_total' => $cartTotal,
        'final_total' => round($finalTotal, 2),
        'savings' => round($discount, 2),
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Coupon apply error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
