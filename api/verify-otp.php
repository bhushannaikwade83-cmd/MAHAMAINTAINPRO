<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database credentials
$servername = "localhost";
$username = "digitrix_maha_user";
$password = "maha_user@70";
$dbname = "digitrix_maha_maintain_pro";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$conn->set_charset("utf8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['phone_number']) || !isset($data['otp'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Phone number and OTP are required']));
    }

    $phone_number = $conn->real_escape_string(trim($data['phone_number']));
    $otp_entered = $conn->real_escape_string(trim($data['otp']));

    // Validate phone number
    if (!preg_match('/^[0-9]{10}$/', $phone_number)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
    }

    // Check OTP
    $sql = "SELECT otp, expires_at, created_at FROM otp_storage
            WHERE phone_number = '$phone_number'
            ORDER BY created_at DESC LIMIT 1";

    $result = $conn->query($sql);

    if ($result->num_rows == 0) {
        http_response_code(401);
        die(json_encode(['success' => false, 'message' => 'OTP not found. Please request a new OTP.']));
    }

    $row = $result->fetch_assoc();
    $stored_otp = $row['otp'];
    $expires_at = $row['expires_at'];

    // Check if OTP is expired
    if (strtotime($expires_at) < time()) {
        http_response_code(401);
        die(json_encode(['success' => false, 'message' => 'OTP has expired. Please request a new OTP.']));
    }

    // Verify OTP
    if ($stored_otp !== $otp_entered) {
        http_response_code(401);
        die(json_encode(['success' => false, 'message' => 'Invalid OTP. Please try again.']));
    }

    // OTP verified successfully
    // Delete used OTP
    $delete_sql = "DELETE FROM otp_storage WHERE phone_number = '$phone_number'";
    $conn->query($delete_sql);

    // Generate session token or return success
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'OTP verified successfully',
        'phone_number' => $phone_number
    ]);

} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'OTP Verification API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
