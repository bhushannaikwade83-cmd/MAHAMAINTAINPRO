<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
$token = verifyJWTToken();
$phoneFromToken = $token['phone_number'];

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

    if (!$input || !isset($input['order_id'])) {
        throw new Exception('Missing order_id');
    }

    $orderId = $input['order_id'];
    $phone = $phoneFromToken;

    // Fetch order details
    $orderQuery = "SELECT * FROM orders WHERE order_id = ? AND phone_number = ?";
    $orderStmt = $conn->prepare($orderQuery);
    if (!$orderStmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    $orderStmt->bind_param("ss", $orderId, $phone);
    $orderStmt->execute();
    $orderResult = $orderStmt->get_result();
    $order = $orderResult->fetch_assoc();
    $orderStmt->close();

    if (!$order) {
        throw new Exception("Order not found or not authorized");
    }

    // Only allow cancellation of pending/requested orders
    $status = $order['current_status'] ?? $order['order_status'] ?? 'pending';
    if ($status !== 'pending' && $status !== 'requested') {
        throw new Exception("Cannot cancel order with status: $status");
    }

    // If payment was made, initiate refund
    if ($order['payment_id'] && $order['payment_status'] === 'completed') {
        // Razorpay refund
        $razorpayOrderId = $order['razorpay_order_id'];
        $totalAmount = $order['total_amount'];

        // Call Razorpay refund API
        $refundAmount = intval($totalAmount * 100); // Convert to paise

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://api.razorpay.com/v1/refunds');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_USERPWD, 'rzp_test_1DP5mmOlF5G0m1:' . 'KqKGfQb9lNsYfVxCqkV6Y12o');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
            'amount' => $refundAmount,
            'payment_id' => $order['payment_id'],
            'notes' => [
                'order_id' => $orderId,
                'reason' => 'Customer cancellation'
            ]
        ]));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

        $refundResponse = curl_exec($ch);
        curl_close($ch);

        $refundData = json_decode($refundResponse, true);

        if ($refundData && isset($refundData['id'])) {
            // Refund initiated successfully
            $refundId = $refundData['id'];
            $refundedAmount = $refundData['amount'] / 100; // Convert from paise

            $updateRefundQuery = "UPDATE orders SET refund_id = ?, refunded_amount = ?, refund_status = 'processed' WHERE order_id = ?";
            $updateRefundStmt = $conn->prepare($updateRefundQuery);
            if (!$updateRefundStmt) {
                throw new Exception("Refund update failed: " . $conn->error);
            }
            $updateRefundStmt->bind_param("sds", $refundId, $refundedAmount, $orderId);
            $updateRefundStmt->execute();
            $updateRefundStmt->close();
        }
    }

    // Delete order items
    $deleteItemsQuery = "DELETE FROM order_items WHERE order_id = ?";
    $deleteItemsStmt = $conn->prepare($deleteItemsQuery);
    if (!$deleteItemsStmt) {
        throw new Exception("Delete items failed: " . $conn->error);
    }
    $deleteItemsStmt->bind_param("s", $orderId);
    $deleteItemsStmt->execute();
    $deleteItemsStmt->close();

    // Delete order
    $deleteOrderQuery = "DELETE FROM orders WHERE order_id = ?";
    $deleteOrderStmt = $conn->prepare($deleteOrderQuery);
    if (!$deleteOrderStmt) {
        throw new Exception("Delete order failed: " . $conn->error);
    }
    $deleteOrderStmt->bind_param("s", $orderId);
    $deleteOrderStmt->execute();
    $deleteOrderStmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Order cancelled successfully',
        'order_id' => $orderId,
        'refund_processed' => isset($refundId),
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("Cancel order error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
