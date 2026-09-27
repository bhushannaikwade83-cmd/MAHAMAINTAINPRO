<?php
header('Content-Type: application/json');

// Server-side safety net: Razorpay calls this URL directly (configure it
// once in the Razorpay Dashboard under Settings > Webhooks, subscribed to
// "payment.captured") whenever a payment succeeds - independent of whether
// the app ever got to call verify-payment.php / pay-maintenance-bill.php.
// Without this, a payment that succeeds right as the customer's app
// crashes or loses network would charge them but never mark the order/bill
// paid in our own database.
require_once 'razorpay-config.php';

$rawBody = file_get_contents('php://input');
$signature = $_SERVER['HTTP_X_RAZORPAY_SIGNATURE'] ?? '';

if (RAZORPAY_WEBHOOK_SECRET === 'REPLACE_WITH_YOUR_RAZORPAY_WEBHOOK_SECRET') {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Webhook secret not configured']));
}

$expectedSignature = hash_hmac('sha256', $rawBody, RAZORPAY_WEBHOOK_SECRET);
if (!hash_equals($expectedSignature, $signature)) {
    http_response_code(401);
    die(json_encode(['success' => false, 'message' => 'Invalid webhook signature']));
}

$event = json_decode($rawBody, true);
$eventType = $event['event'] ?? '';

// payment.captured reconciles a payment the app itself may have missed;
// payment.failed is the only reliable source of truth for a "Payment
// failed" push (a failure in the app is purely local/client-side and
// never reaches the server otherwise). Refunds already go through
// process-refund.php synchronously, and other events aren't acted on.
if (!in_array($eventType, ['payment.captured', 'payment.failed'], true)) {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Event ignored']);
    exit;
}

$payment = $event['payload']['payment']['entity'] ?? null;
if (!$payment || empty($payment['order_id']) || empty($payment['id'])) {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'No payment entity to process']);
    exit;
}

$razorpayOrderId = $payment['order_id'];
$paymentId = $payment['id'];

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

require_once 'ensure-orders-schema.php';
if (!$conn->connect_error) {
    ensureOrdersSchema($conn);
}
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

require_once 'push-notification-helper.php';

try {
    // Case 1: a home-service order stuck in 'pending' despite Razorpay
    // having actually captured the payment (or, for payment.failed,
    // still pending because it genuinely failed).
    $orderStmt = $conn->prepare("SELECT order_id, phone_number, payment_status FROM orders WHERE razorpay_order_id = ?");
    $orderStmt->bind_param('s', $razorpayOrderId);
    $orderStmt->execute();
    $order = $orderStmt->get_result()->fetch_assoc();
    $orderStmt->close();

    if ($order) {
        if ($eventType === 'payment.captured' && $order['payment_status'] !== 'completed') {
            $update = $conn->prepare("UPDATE orders SET payment_status = 'completed', payment_id = ? WHERE order_id = ?");
            $update->bind_param('ss', $paymentId, $order['order_id']);
            $update->execute();
            $update->close();
        } elseif ($eventType === 'payment.failed') {
            $reason = $payment['error_description'] ?? 'Payment could not be completed';
            sendPushToPhone($conn, $order['phone_number'], 'Payment failed', $reason, ['type' => 'payment_failed', 'order_id' => $order['order_id']]);
        }
        http_response_code(200);
        echo json_encode(['success' => true, 'message' => 'Order reconciled', 'order_id' => $order['order_id']]);
        $conn->close();
        exit;
    }

    // Case 2: a maintenance bill stuck 'due' despite being captured.
    $billStmt = $conn->prepare("
        SELECT b.id, b.status, i.phone_number FROM society_maintenance_bills b
        JOIN society_customers_individual m ON m.flat_id = b.flat_id
        JOIN individuals i ON i.phone_number = m.phone
        WHERE b.razorpay_order_id = ?
        LIMIT 1
    ");
    $billStmt->bind_param('s', $razorpayOrderId);
    $billStmt->execute();
    $bill = $billStmt->get_result()->fetch_assoc();
    $billStmt->close();

    if ($bill) {
        if ($eventType === 'payment.captured' && $bill['status'] !== 'paid') {
            $update = $conn->prepare("UPDATE society_maintenance_bills SET status = 'paid', payment_id = ?, paid_at = NOW() WHERE id = ?");
            $update->bind_param('si', $paymentId, $bill['id']);
            $update->execute();
            $update->close();
        } elseif ($eventType === 'payment.failed') {
            $reason = $payment['error_description'] ?? 'Payment could not be completed';
            sendPushToPhone($conn, $bill['phone_number'], 'Payment failed', $reason, ['type' => 'payment_failed', 'bill_id' => (string)$bill['id']]);
        }
        http_response_code(200);
        echo json_encode(['success' => true, 'message' => 'Bill reconciled', 'bill_id' => $bill['id']]);
        $conn->close();
        exit;
    }

    // Nothing matched this razorpay_order_id - not necessarily an error,
    // could be a payment from before this column existed.
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'No matching order or bill found']);
} catch (Exception $e) {
    http_response_code(500);
    error_log('Razorpay webhook error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
