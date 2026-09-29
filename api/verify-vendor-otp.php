<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$data = json_decode(file_get_contents("php://input"), true);
$phone = trim($data['phone_number'] ?? '');
$otp_entered = trim($data['otp'] ?? '');

// Remove country code if present
$phone = preg_replace('/^\+91|^91/', '', $phone);

if (!preg_match('/^[0-9]{10}$/', $phone)) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
}

require_once 'rate-limiter.php';

// Max 5 guesses per 10 minutes per phone number
checkRateLimit('verify_otp_' . $phone, 5, 600);

// Ensure otp_storage table exists
$createOtpTable = "CREATE TABLE IF NOT EXISTS otp_storage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
$conn->query($createOtpTable);

// Use customer app's otp_storage table
$sql = "SELECT otp, expires_at FROM otp_storage
        WHERE phone_number = '$phone'
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

// OTP verified - delete it
$delete_sql = "DELETE FROM otp_storage WHERE phone_number = '$phone'";
$conn->query($delete_sql);

// Ensure vendors table exists
$createVendors = "CREATE TABLE IF NOT EXISTS vendors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255),
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(255),
    rating DECIMAL(3, 2) DEFAULT 0,
    total_services INT DEFAULT 0,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)";
$conn->query($createVendors);

// Check if vendor exists
$check = $conn->prepare('SELECT id, vendor_id, name, email FROM vendors WHERE phone = ?');
$check->bind_param('s', $phone);
$check->execute();
$result = $check->get_result();
$check->close();

if ($result->num_rows > 0) {
    // Vendor exists
    $vendor = $result->fetch_assoc();
    $vendor_id = $vendor['vendor_id'];
    $name = $vendor['name'];
    $email = $vendor['email'];
    $exists = true;

    // Check if MPIN is set
    $checkMpin = $conn->prepare('SELECT id FROM vendor_mpin WHERE phone_number = ?');
    $checkMpin->bind_param('s', $phone);
    $checkMpin->execute();
    $has_mpin = $checkMpin->get_result()->num_rows > 0;
    $checkMpin->close();
} else {
    // New vendor - needs registration
    $exists = false;
    $vendor_id = 'temp_' . uniqid();
    $name = null;
    $email = null;
    $has_mpin = false;
}

// Generate JWT token (vendor role)
$token = generateJWT([
    'phone_number' => $phone,
    'vendor_id' => $vendor_id,
    'type' => 'vendor_auth',
    'role' => 'vendor',
], 86400);

http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'OTP verified',
    'token' => $token,
    'exists' => $exists,
    'vendor_id' => $vendor_id,
    'name' => $name,
    'email' => $email,
    'has_mpin' => $has_mpin
]);

$conn->close();
?>
