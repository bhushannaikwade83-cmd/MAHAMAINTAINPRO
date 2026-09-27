<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Rate limiting (this is a login endpoint - protect against 4-digit PIN brute force)
require_once 'rate-limiter.php';

// JWT issuance (mirrors verify-otp.php)
define('JWT_SECRET', getenv('JWT_SECRET') ?: 'your-super-secret-jwt-key-change-in-production');

function generateJWTTokenForMpin($phoneNumber) {
    $header = json_encode(['alg' => 'HS256', 'typ' => 'JWT']);
    $payload = json_encode([
        'phone_number' => $phoneNumber,
        'iat' => time(),
        'exp' => time() + 86400,
        'type' => 'user_auth',
        'role' => 'resident'
    ]);

    $base64Header = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
    $base64Payload = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');

    $signature = hash_hmac('sha256', "$base64Header.$base64Payload", JWT_SECRET, true);
    $base64Signature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

    return "$base64Header.$base64Payload.$base64Signature";
}

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input || empty($input['phone_number']) || empty($input['mpin'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'phone_number and mpin are required']);
        exit;
    }

    $phoneNumber = $input['phone_number'];
    $mpin = $input['mpin'];

    // Max 5 attempts per 5 minutes per phone number
    checkRateLimit('mpin_' . $phoneNumber, 5, 300);

    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database connection failed']);
        exit;
    }

    // Fetch M-PIN hash for the phone number
    $stmt = $conn->prepare("SELECT mpin_hash FROM user_mpin WHERE phone_number = ?");

    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $conn->error]);
        $conn->close();
        exit;
    }

    $stmt->bind_param("s", $phoneNumber);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        http_response_code(401);
        echo json_encode(['success' => false, 'error' => 'M-PIN not set for this phone number']);
        $stmt->close();
        $conn->close();
        exit;
    }

    $row = $result->fetch_assoc();
    $storedHash = $row['mpin_hash'];

    // Verify the M-PIN using password_verify
    if (password_verify($mpin, $storedHash)) {
        $jwtToken = generateJWTTokenForMpin($phoneNumber);
        echo json_encode([
            'success' => true,
            'message' => 'M-PIN verified successfully',
            'token' => $jwtToken,
            'token_type' => 'Bearer',
            'expires_in' => 86400
        ]);
    } else {
        http_response_code(401);
        echo json_encode(['success' => false, 'error' => 'Incorrect M-PIN']);
    }

    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
