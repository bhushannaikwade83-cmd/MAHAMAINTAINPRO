<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// JWT Secret Key (should be in environment variable in production)
define('JWT_SECRET', getenv('JWT_SECRET') ?: 'your-super-secret-jwt-key-change-in-production');
define('JWT_EXPIRY', 86400); // 24 hours

try {
    $input = json_decode(file_get_contents('php://input'), true);

    $phoneNumber = $input['phone_number'] ?? null;
    $mpin = $input['mpin'] ?? null;

    if (!$phoneNumber) {
        throw new Exception('Phone number required');
    }

    // Create JWT Token
    $header = json_encode(['alg' => 'HS256', 'typ' => 'JWT']);
    $payload = json_encode([
        'phone_number' => $phoneNumber,
        'iat' => time(),
        'exp' => time() + JWT_EXPIRY,
        'type' => 'user_auth'
    ]);

    $base64Header = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
    $base64Payload = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');

    $signature = hash_hmac('sha256', "$base64Header.$base64Payload", JWT_SECRET, true);
    $base64Signature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

    $jwt = "$base64Header.$base64Payload.$base64Signature";

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'token' => $jwt,
        'phone_number' => $phoneNumber,
        'expires_in' => JWT_EXPIRY,
        'token_type' => 'Bearer'
    ]);

} catch (Exception $e) {
    http_response_code(400);
    error_log("JWT generation error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}
?>
