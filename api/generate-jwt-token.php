<?php
// This endpoint used to issue a token for any phone number with no proof of
// identity. Tokens are now issued only by verify-otp.php and verify-mpin.php.
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

http_response_code(410);
echo json_encode(['success' => false, 'message' => 'This endpoint is no longer available. Log in with OTP or M-PIN to get a token.']);
?>
