<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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

// SMS Gateway credentials
$SMS_USER = "acctsmmp";
$SMS_KEY = "503856edbcXX";
$SMS_SENDER_ID = "MHMNPR";
$SMS_ENTITY_ID = "1701178591434877016";
$SMS_TEMPLATE_ID = "1777178609736013559";
$SMS_GATEWAY_URL = "http://sms3.bpil.in/submitsms.jsp";

try {
    $data = json_decode(file_get_contents("php://input"), true);

    $order_id = $data['order_id'] ?? null;
    $vendor_id = $data['vendor_id'] ?? null;

    if (!$order_id || !$vendor_id) {
        throw new Exception('Missing order_id or vendor_id');
    }

    // Get customer phone number from order
    $query = "SELECT phone_number FROM orders WHERE order_id = ? AND vendor_id = ?";
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    $stmt->bind_param("ss", $order_id, $vendor_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        throw new Exception("Order not found or not assigned to this vendor");
    }

    $row = $result->fetch_assoc();
    $phone_number = $row['phone_number'];
    $stmt->close();

    // Generate 4-digit OTP
    $otp = str_pad(rand(0, 9999), 4, '0', STR_PAD_LEFT);
    $expires_at = date('Y-m-d H:i:s', strtotime('+15 minutes'));

    // Store OTP in database (completion_otp_storage table)
    $insert_sql = "INSERT INTO completion_otp_storage
                   (order_id, phone_number, otp, expires_at, created_at)
                   VALUES (?, ?, ?, ?, NOW())
                   ON DUPLICATE KEY UPDATE
                   otp = ?, expires_at = ?, created_at = NOW()";

    $insertStmt = $conn->prepare($insert_sql);
    if (!$insertStmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $insertStmt->bind_param("ssssss", $order_id, $phone_number, $otp, $expires_at, $otp, $expires_at);
    if (!$insertStmt->execute()) {
        throw new Exception("Failed to store OTP: " . $conn->error);
    }
    $insertStmt->close();

    // Send SMS to customer
    $message = "$otp is your OTP to confirm service completion. Valid for 15 minutes. Do not share this OTP.";

    $sms_params = array(
        'user' => $SMS_USER,
        'key' => $SMS_KEY,
        'mobile' => '91' . $phone_number,
        'message' => $message,
        'senderid' => $SMS_SENDER_ID,
        'accusage' => '1',
        'entityid' => $SMS_ENTITY_ID,
        'tempid' => $SMS_TEMPLATE_ID
    );

    $sms_url = $SMS_GATEWAY_URL . '?' . http_build_query($sms_params);

    try {
        $context = stream_context_create(['http' => ['timeout' => 5]]);
        $response = @file_get_contents($sms_url, false, $context);

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'OTP sent to customer',
            'phone' => substr($phone_number, -4),
            'expires_in' => 900
        ]);
    } catch (Exception $e) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'OTP generated',
            'phone' => substr($phone_number, -4),
            'expires_in' => 900
        ]);
    }

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?>
