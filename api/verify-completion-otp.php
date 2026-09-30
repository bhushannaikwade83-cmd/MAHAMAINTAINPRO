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

try {
    $data = json_decode(file_get_contents("php://input"), true);

    $order_id = $data['order_id'] ?? null;
    $otp = $data['otp'] ?? null;

    if (!$order_id || !$otp) {
        throw new Exception('Missing order_id or otp');
    }

    // Verify OTP
    $query = "SELECT otp, expires_at FROM completion_otp_storage
              WHERE order_id = ? AND otp = ? AND expires_at > NOW()";
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }

    $stmt->bind_param("ss", $order_id, $otp);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        throw new Exception("Invalid or expired OTP");
    }

    $stmt->close();

    // OTP is valid
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'OTP verified successfully',
        'verified' => true
    ]);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'verified' => false
    ]);
}

$conn->close();
?>
