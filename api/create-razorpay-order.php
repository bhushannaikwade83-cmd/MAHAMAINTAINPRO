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
// !! REPLACE THIS with your actual Razorpay Key Secret from the Razorpay
// dashboard (Settings > API Keys). Never put the secret in the Flutter
// app - only here, server-side.
$RAZORPAY_KEY_ID = 'rzp_live_TUUuGaHfai8zhj';
$RAZORPAY_KEY_SECRET = 'REPLACE_WITH_YOUR_RAZORPAY_KEY_SECRET';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Method not allowed']));
}

$data = json_decode(file_get_contents("php://input"), true);
$amountRupees = $data['amount'] ?? null;
$receipt = $data['receipt'] ?? ('rcpt_' . time());

if ($amountRupees === null || !is_numeric($amountRupees) || $amountRupees <= 0) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'A positive amount (in rupees) is required']));
}

if ($RAZORPAY_KEY_SECRET === 'REPLACE_WITH_YOUR_RAZORPAY_KEY_SECRET') {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Server is not configured with a Razorpay key secret yet']));
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
    CURLOPT_USERPWD => "$RAZORPAY_KEY_ID:$RAZORPAY_KEY_SECRET",
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
    die(json_encode([
        'success' => false,
        'message' => $result['error']['description'] ?? 'Razorpay order creation failed',
    ]));
}

echo json_encode([
    'success' => true,
    'order_id' => $result['id'],
    'amount' => $result['amount'],
    'currency' => $result['currency'],
]);
?>
