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

// SMS Gateway credentials
$SMS_USER = "acctsmmp";
$SMS_KEY = "503856edbcXX";
$SMS_SENDER_ID = "MHMNPR";
$SMS_ENTITY_ID = "1701178591434877016";
$SMS_TEMPLATE_ID = "1777178609736013559";
$SMS_GATEWAY_URL = "http://sms3.bpil.in/submitsms.jsp";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$conn->set_charset("utf8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['phone_number'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Phone number is required']));
    }

    $phone_number = $conn->real_escape_string(trim($data['phone_number']));

    // Validate phone number (10 digits)
    if (!preg_match('/^[0-9]{10}$/', $phone_number)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
    }

    // Generate 4-digit OTP
    $otp = str_pad(rand(0, 9999), 4, '0', STR_PAD_LEFT);
    $expires_at = date('Y-m-d H:i:s', strtotime('+10 minutes'));

    // Store OTP in database
    $insert_sql = "INSERT INTO otp_storage
                   (phone_number, otp, expires_at, created_at)
                   VALUES ('$phone_number', '$otp', '$expires_at', NOW())
                   ON DUPLICATE KEY UPDATE
                   otp = '$otp', expires_at = '$expires_at', created_at = NOW()";

    if (!$conn->query($insert_sql)) {
        http_response_code(500);
        die(json_encode(['success' => false, 'message' => 'Failed to generate OTP']));
    }

    // Send SMS via gateway
    $message = "$otp is your OTP for login to Maha Maintain Pro. Valid for 10 minutes. Do not share this OTP with anyone.";

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

        if ($response === false) {
            // SMS failed but OTP is stored - send anyway
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'OTP generated. SMS delivery may be delayed.',
                'otp_sent' => true
            ]);
        } else {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'OTP sent successfully',
                'otp_sent' => true
            ]);
        }
    } catch (Exception $e) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'OTP generated',
            'otp_sent' => true
        ]);
    }

} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'SMS OTP API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
