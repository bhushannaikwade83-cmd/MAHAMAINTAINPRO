<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'razorpay-config.php';
require_once 'jwt-auth.php';
$token = verifyJWTToken();

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

require_once 'ensure-orders-schema.php';
if (!$conn->connect_error) {
    ensureOrdersSchema($conn);
}

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

    $orderId = $input['order_id'] ?? null;
    $paymentId = $input['payment_id'] ?? null;
    $razorpayOrderId = $input['razorpay_order_id'] ?? null;
    $signature = $input['signature'] ?? null;
    $method = strtoupper($input['method'] ?? '');

    if (!$orderId || !$paymentId) {
        throw new Exception('Missing required fields');
    }

    // Order must belong to the authenticated user - stops one customer
    // from marking someone else's order as paid.
    $ownerStmt = $conn->prepare('SELECT phone_number FROM orders WHERE order_id = ?');
    $ownerStmt->bind_param('s', $orderId);
    $ownerStmt->execute();
    $ownerRow = $ownerStmt->get_result()->fetch_assoc();
    $ownerStmt->close();

    if (!$ownerRow) {
        throw new Exception('Order not found');
    }
    if ($ownerRow['phone_number'] !== $token['phone_number']) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'This order does not belong to you']));
    }

    // COD has no payment gateway to verify against - the only genuinely
    // gateway-free method. Everything else must have gone through Razorpay
    // and therefore must carry a verifiable signature.
    if ($method !== 'COD') {
        if (!$razorpayOrderId || !$signature) {
            throw new Exception('Missing payment verification data');
        }

        if (RAZORPAY_KEY_SECRET === 'REPLACE_WITH_YOUR_RAZORPAY_KEY_SECRET') {
            http_response_code(500);
            die(json_encode(['success' => false, 'message' => 'Server is not configured with a Razorpay key secret yet']));
        }

        // Razorpay's documented signature: HMAC-SHA256 of
        // "razorpay_order_id|razorpay_payment_id" keyed with the key_secret.
        $expectedSignature = hash_hmac('sha256', $razorpayOrderId . '|' . $paymentId, RAZORPAY_KEY_SECRET);

        if (!hash_equals($expectedSignature, $signature)) {
            http_response_code(401);
            die(json_encode(['success' => false, 'message' => 'Invalid payment signature']));
        }
    }

    // Update order with payment details
    $query = "UPDATE orders SET payment_status = 'completed', payment_id = ? WHERE order_id = ?";
    $stmt = $conn->prepare($query);

    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param("ss", $paymentId, $orderId);

    if (!$stmt->execute()) {
        throw new Exception("Payment verification failed: " . $stmt->error);
    }
    $stmt->close();

    // Fetch updated order
    $selectQuery = "SELECT * FROM orders WHERE order_id = ?";
    $selectStmt = $conn->prepare($selectQuery);
    $selectStmt->bind_param("s", $orderId);
    $selectStmt->execute();
    $result = $selectStmt->get_result();
    $order = $result->fetch_assoc();
    $selectStmt->close();

    require_once 'push-notification-helper.php';
    sendPushToPhone(
        $conn,
        $token['phone_number'],
        'Payment successful',
        "Your payment of ₹{$order['total_amount']} for order $orderId was successful.",
        ['type' => 'payment', 'order_id' => $orderId]
    );

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Payment verified successfully',
        'order_id' => $orderId,
        'payment_id' => $paymentId,
        'order' => $order,
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Payment verification error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
