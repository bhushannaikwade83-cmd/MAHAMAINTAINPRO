<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Razorpay checkout will reject any order_id the client makes up (e.g. a
// timestamp string) - it must be a real order created via Razorpay's
// Orders API using your key_secret. This does that server-side and hands
// back the real order_id for the app to open checkout with.
//
// SECURITY: the amount charged is NEVER taken from the client. Pass
// order_id (a home-service order) or bill_id (a maintenance bill) and the
// amount is recomputed here from the authoritative DB records - the
// `services` catalog price and the server-verified coupon for orders, or
// the live-recomputed late fee for bills. A bare client-supplied `amount`
// with neither id is only accepted for non-order/non-bill legacy callers,
// if any remain - never trust it for a real payment.
require_once 'razorpay-config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Method not allowed']));
}

$data = json_decode(file_get_contents("php://input"), true);
$orderId = $data['order_id'] ?? null;
$billId = isset($data['bill_id']) ? (int)$data['bill_id'] : null;
$receipt = $data['receipt'] ?? ('rcpt_' . time());

if (RAZORPAY_KEY_SECRET === 'REPLACE_WITH_YOUR_RAZORPAY_KEY_SECRET') {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Server is not configured with a Razorpay key secret yet']));
}

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

require_once 'ensure-orders-schema.php';
if (!$conn->connect_error) {
    ensureOrdersSchema($conn);
}
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

if ($orderId) {
    // Re-price every item from the `services` catalog - ignores
    // order_items.price/subtotal entirely, since those were only ever
    // client-supplied at save-order-items.php time.
    $itemsStmt = $conn->prepare('SELECT service_id, quantity FROM order_items WHERE order_id = ?');
    $itemsStmt->bind_param('s', $orderId);
    $itemsStmt->execute();
    $items = $itemsStmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $itemsStmt->close();

    if (empty($items)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Order has no items to price']));
    }

    $subtotal = 0;
    $priceStmt = $conn->prepare('SELECT price FROM services WHERE id = ? AND is_active = 1');
    foreach ($items as $item) {
        $priceStmt->bind_param('i', $item['service_id']);
        $priceStmt->execute();
        $priceRow = $priceStmt->get_result()->fetch_assoc();
        if (!$priceRow) {
            http_response_code(400);
            die(json_encode(['success' => false, 'message' => "Service #{$item['service_id']} is no longer available"]));
        }
        $subtotal += (float)$priceRow['price'] * max(1, (int)$item['quantity']);
    }
    $priceStmt->close();

    $deliveryFee = 50; // matches the flat fee shown in checkout_screen.dart
    $amountRupees = $subtotal + $deliveryFee;

    // Re-validate any coupon stored on the order against THIS server-priced
    // subtotal - never the client's discount_amount.
    $couponStmt = $conn->prepare('SELECT coupon_code FROM orders WHERE order_id = ?');
    $couponStmt->bind_param('s', $orderId);
    $couponStmt->execute();
    $orderRow = $couponStmt->get_result()->fetch_assoc();
    $couponStmt->close();

    $discountAmount = 0;
    if ($orderRow && !empty($orderRow['coupon_code'])) {
        $couponQuery = $conn->prepare("
            SELECT discount_type, discount_value, min_amount, max_discount
            FROM coupons
            WHERE code = ? AND is_active = 1 AND (valid_until IS NULL OR valid_until > NOW())
            LIMIT 1
        ");
        $couponQuery->bind_param('s', $orderRow['coupon_code']);
        $couponQuery->execute();
        $coupon = $couponQuery->get_result()->fetch_assoc();
        $couponQuery->close();

        if ($coupon && $subtotal >= (float)($coupon['min_amount'] ?? 0)) {
            if ($coupon['discount_type'] === 'percentage') {
                $discountAmount = $subtotal * ((float)$coupon['discount_value'] / 100);
                if (!empty($coupon['max_discount'])) {
                    $discountAmount = min($discountAmount, (float)$coupon['max_discount']);
                }
            } else {
                $discountAmount = (float)$coupon['discount_value'];
            }
            $amountRupees = max(0, $amountRupees - $discountAmount);
        }
    }

    // The order row now reflects exactly what will be charged.
    $updateStmt = $conn->prepare('UPDATE orders SET total_amount = ?, discount_amount = ? WHERE order_id = ?');
    $updateStmt->bind_param('dds', $amountRupees, $discountAmount, $orderId);
    $updateStmt->execute();
    $updateStmt->close();
} elseif ($billId) {
    $conn->query("
        UPDATE society_maintenance_bills
        SET late_fee = ROUND(amount * 0.02 * GREATEST(FLOOR(DATEDIFF(CURDATE(), due_date) / 30), 0), 2)
        WHERE id = $billId AND status = 'due' AND due_date IS NOT NULL AND due_date < CURDATE()
    ");

    $billStmt = $conn->prepare('SELECT amount, late_fee, status FROM society_maintenance_bills WHERE id = ?');
    $billStmt->bind_param('i', $billId);
    $billStmt->execute();
    $bill = $billStmt->get_result()->fetch_assoc();
    $billStmt->close();

    if (!$bill) {
        http_response_code(404);
        die(json_encode(['success' => false, 'message' => 'Bill not found']));
    }
    if ($bill['status'] === 'paid') {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'This bill is already paid']));
    }

    $amountRupees = (float)$bill['amount'] + (float)$bill['late_fee'];
} else {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'order_id or bill_id is required']));
}

if ($amountRupees === null || !is_numeric($amountRupees) || $amountRupees <= 0) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'Could not determine a valid amount to charge']));
}

$payload = json_encode([
    'amount' => (int) round($amountRupees * 100), // paise
    'currency' => 'INR',
    'receipt' => $receipt,
]);

$ch = curl_init('https://api.razorpay.com/v1/orders');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => $payload,
    CURLOPT_USERPWD => RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_TIMEOUT => 15,
]);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

if ($response === false) {
    http_response_code(502);
    die(json_encode(['success' => false, 'message' => "Could not reach Razorpay: $curlError"]));
}

$result = json_decode($response, true);

if ($httpCode !== 200 || !isset($result['id'])) {
    http_response_code(502);
    $conn->close();
    die(json_encode([
        'success' => false,
        'message' => $result['error']['description'] ?? 'Razorpay order creation failed',
    ]));
}

// Store the real Razorpay order id so razorpay-webhook.php can find this
// order/bill later purely from a payment.captured event, even if the app
// never calls verify-payment.php / pay-maintenance-bill.php (e.g. it
// crashed or lost connection right after a successful charge).
if ($orderId) {
    $stmt = $conn->prepare('UPDATE orders SET razorpay_order_id = ? WHERE order_id = ?');
    $stmt->bind_param('ss', $result['id'], $orderId);
    $stmt->execute();
} elseif ($billId) {
    $stmt = $conn->prepare('UPDATE society_maintenance_bills SET razorpay_order_id = ? WHERE id = ?');
    $stmt->bind_param('si', $result['id'], $billId);
    $stmt->execute();
}
$conn->close();

echo json_encode([
    'success' => true,
    'order_id' => $result['id'],
    'amount' => $result['amount'],
    'currency' => $result['currency'],
]);
?>
