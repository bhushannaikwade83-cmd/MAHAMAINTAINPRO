<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Use same OTP approach as customer app
require_once 'rate-limiter.php';

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    $phone_number = $conn->real_escape_string(trim($data['phone_number'] ?? ''));

// Remove country code if present
$phone_number = preg_replace('/^\+91|^91/', '', $phone_number);

if (!preg_match('/^[0-9]{10}$/', $phone_number)) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
}

// Check rate limit: Max 3 OTP requests per 5 minutes
checkRateLimit('otp_' . $phone_number, 3, 300);

// Ensure otp_storage table exists (shared with customer app)
$createOtpTable = "CREATE TABLE IF NOT EXISTS otp_storage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
$conn->query($createOtpTable);

// Ensure vendor_mpin table exists
$createMpinTable = "CREATE TABLE IF NOT EXISTS vendor_mpin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    mpin_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
$conn->query($createMpinTable);

// Check if MPIN exists
$checkMpin = $conn->prepare('SELECT id FROM vendor_mpin WHERE phone_number = ?');
$checkMpin->bind_param('s', $phone_number);
$checkMpin->execute();
$hasMpin = $checkMpin->get_result()->num_rows > 0;
$checkMpin->close();

if ($hasMpin && !($data['force_otp'] ?? false)) {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'requires_mpin' => true,
        'message' => 'M-PIN required for this vendor'
    ]);
    exit();
}

// Use customer app's otp_storage table
$otp = str_pad(rand(0, 9999), 4, '0', STR_PAD_LEFT);
$expires_at = date('Y-m-d H:i:s', strtotime('+10 minutes'));

$insert_sql = "INSERT INTO otp_storage
               (phone_number, otp, expires_at, created_at)
               VALUES ('$phone_number', '$otp', '$expires_at', NOW())
               ON DUPLICATE KEY UPDATE
               otp = '$otp', expires_at = '$expires_at', created_at = NOW()";

if (!$conn->query($insert_sql)) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Failed to generate OTP']));
}

// Log OTP for development
error_log("Vendor OTP for +91$phone_number: $otp");

// SMS Gateway credentials (same as customer app)
$SMS_USER = "acctsmmp";
$SMS_KEY = "503856edbcXX";
$SMS_SENDER_ID = "MHMNPR";
$SMS_ENTITY_ID = "1701178591434877016";
$SMS_TEMPLATE_ID = "1777178609736013559";
$SMS_GATEWAY_URL = "http://sms3.bpil.in/submitsms.jsp";

// Send SMS via gateway
$message = "$otp is your OTP for login to Maha Maintain Pro Partner App. Valid for 10 minutes. Do not share this OTP with anyone.";

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

// Log SMS attempt for debugging
error_log("SMS sending attempt for $phone_number: URL=$sms_url");

try {
    $context = stream_context_create(['http' => ['timeout' => 5]]);
    $response = @file_get_contents($sms_url, false, $context);
    error_log("SMS response: " . ($response === false ? "FAILED" : "SUCCESS - $response"));

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
            'message' => 'OTP sent successfully to vendor phone',
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
    echo json_encode(['success' => true, 'message' => 'Vendor OTP API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
