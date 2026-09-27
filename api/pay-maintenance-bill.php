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

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    $input = json_decode(file_get_contents('php://input'), true);

    $billId = intval($input['bill_id'] ?? 0);
    $paymentId = $input['payment_id'] ?? null;
    $razorpayOrderId = $input['razorpay_order_id'] ?? null;
    $signature = $input['signature'] ?? null;

    if ($billId <= 0 || !$paymentId || !$razorpayOrderId || !$signature) {
        throw new Exception('Missing required payment fields');
    }

    // Bill must belong to a flat this authenticated user is owner/tenant
    // of - stops one resident from paying/marking someone else's bill.
    $ownerStmt = $conn->prepare("
        SELECT b.id FROM society_maintenance_bills b
        JOIN society_customers_individual m ON m.flat_id = b.flat_id
        WHERE b.id = ? AND m.phone = ?
    ");
    $ownerStmt->bind_param('is', $billId, $token['phone_number']);
    $ownerStmt->execute();
    $owns = $ownerStmt->get_result()->num_rows > 0;
    $ownerStmt->close();

    if (!$owns) {
        http_response_code(403);
        die(json_encode(['success' => false, 'message' => 'This bill does not belong to you']));
    }

    if (RAZORPAY_KEY_SECRET === 'REPLACE_WITH_YOUR_RAZORPAY_KEY_SECRET') {
        http_response_code(500);
        die(json_encode(['success' => false, 'message' => 'Server is not configured with a Razorpay key secret yet']));
    }

    $expectedSignature = hash_hmac('sha256', $razorpayOrderId . '|' . $paymentId, RAZORPAY_KEY_SECRET);
    if (!hash_equals($expectedSignature, $signature)) {
        http_response_code(401);
        die(json_encode(['success' => false, 'message' => 'Invalid payment signature']));
    }

    $stmt = $conn->prepare("UPDATE society_maintenance_bills SET status = 'paid', payment_id = ?, paid_at = NOW() WHERE id = ?");
    $stmt->bind_param('si', $paymentId, $billId);
    $stmt->execute();
    $stmt->close();

    $selectStmt = $conn->prepare("
        SELECT b.*, f.flat_number FROM society_maintenance_bills b
        JOIN society_flats f ON f.id = b.flat_id
        WHERE b.id = ?
    ");
    $selectStmt->bind_param('i', $billId);
    $selectStmt->execute();
    $bill = $selectStmt->get_result()->fetch_assoc();
    $selectStmt->close();

    require_once 'push-notification-helper.php';
    $totalPaid = (float)$bill['amount'] + (float)$bill['late_fee'];
    sendPushToPhone(
        $conn,
        $token['phone_number'],
        'Payment successful',
        "Your maintenance payment of ₹{$totalPaid} for {$bill['period_month']} (Flat {$bill['flat_number']}) was successful.",
        ['type' => 'maintenance_payment', 'bill_id' => (string)$billId]
    );

    echo json_encode([
        'success' => true,
        'message' => 'Payment verified successfully',
        'bill' => $bill,
    ]);
} catch (Exception $e) {
    http_response_code(400);
    error_log('Maintenance payment verification error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
