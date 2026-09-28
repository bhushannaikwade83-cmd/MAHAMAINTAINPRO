<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Issue tokens through the shared jwt-auth.php secret/signer - see
// verify-otp.php for why a locally-hardcoded secret here breaks every
// later authenticated request.
require_once 'jwt-auth.php';
define('JWT_EXPIRY', 86400); // 24 hours

try {
    $input = json_decode(file_get_contents('php://input'), true);

    $phoneNumber = $input['phone_number'] ?? null;

    if (!$phoneNumber) {
        throw new Exception('Phone number required');
    }

    $jwt = generateJWT([
        'phone_number' => $phoneNumber,
        'type' => 'user_auth',
        'role' => 'resident',
    ], JWT_EXPIRY);

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
