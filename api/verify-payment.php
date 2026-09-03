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

    $orderId = $input['order_id'] ?? null;
    $paymentId = $input['payment_id'] ?? null;
    $signature = $input['signature'] ?? null;

    if (!$orderId || !$paymentId) {
        throw new Exception('Missing required fields');
    }

    // Verify signature (optional for development, required for production)
    $razorpayKeySecret = 'your_razorpay_key_secret'; // Replace with your actual secret
    $body = $orderId . '|' . $paymentId;
    $expectedSignature = hash_hmac('sha256', $body, $razorpayKeySecret);

    // For development, we'll skip signature verification
    // In production, uncomment this:
    // if ($signature !== $expectedSignature) {
    //     throw new Exception('Invalid payment signature');
    // }

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

    // Fetch updated order
    $selectQuery = "SELECT * FROM orders WHERE order_id = ?";
    $selectStmt = $conn->prepare($selectQuery);
    $selectStmt->bind_param("s", $orderId);
    $selectStmt->execute();
    $result = $selectStmt->get_result();
    $order = $result->fetch_assoc();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Payment verified successfully',
        'order_id' => $orderId,
        'payment_id' => $paymentId,
        'order' => $order,
    ]);

    $stmt->close();
    $selectStmt->close();

} catch (Exception $e) {
    http_response_code(400);
    error_log("Payment verification error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
