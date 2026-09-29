<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

error_log("=== TEST VENDOR OTP ENDPOINT ===");
error_log("METHOD: " . $_SERVER['REQUEST_METHOD']);
error_log("POST DATA: " . file_get_contents("php://input"));

$data = json_decode(file_get_contents("php://input"), true);
$phone = $data['phone_number'] ?? 'NO_PHONE';

error_log("Phone: $phone");

// Test SMS gateway
$SMS_USER = "acctsmmp";
$SMS_KEY = "503856edbcXX";
$SMS_SENDER_ID = "MHMNPR";
$SMS_ENTITY_ID = "1701178591434877016";
$SMS_TEMPLATE_ID = "1777178609736013559";
$SMS_GATEWAY_URL = "http://sms3.bpil.in/submitsms.jsp";

$test_otp = "9999";
$message = "TEST OTP: $test_otp";

$sms_params = array(
    'user' => $SMS_USER,
    'key' => $SMS_KEY,
    'mobile' => '91' . $phone,
    'message' => $message,
    'senderid' => $SMS_SENDER_ID,
    'accusage' => '1',
    'entityid' => $SMS_ENTITY_ID,
    'tempid' => $SMS_TEMPLATE_ID
);

$sms_url = $SMS_GATEWAY_URL . '?' . http_build_query($sms_params);
error_log("SMS URL: $sms_url");

$context = stream_context_create(['http' => ['timeout' => 5]]);
$response = @file_get_contents($sms_url, false, $context);

error_log("SMS Response: " . ($response === false ? "FAILED" : $response));

http_response_code(200);
echo json_encode([
    'success' => true,
    'test' => 'SMS test endpoint',
    'phone' => $phone,
    'sms_response' => $response === false ? "FAILED" : "SUCCESS"
]);
?>
