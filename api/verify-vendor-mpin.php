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
$mpin_entered = trim($data['mpin'] ?? '');

// Remove country code if present
$phone = preg_replace('/^\+91|^91/', '', $phone);

if (!preg_match('/^[0-9]{10}$/', $phone) || !preg_match('/^[0-9]{4}$/', $mpin_entered)) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'Invalid phone or M-PIN']));
}

// Ensure vendor_mpin table exists
$createMpinTable = "CREATE TABLE IF NOT EXISTS vendor_mpin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    mpin_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
$conn->query($createMpinTable);

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

// Verify MPIN
$stmt = $conn->prepare('SELECT mpin_hash FROM vendor_mpin WHERE phone_number = ?');
$stmt->bind_param('s', $phone);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    http_response_code(401);
    die(json_encode(['success' => false, 'message' => 'M-PIN not found']));
}

$row = $result->fetch_assoc();
$stmt->close();

if (!password_verify($mpin_entered, $row['mpin_hash'])) {
    http_response_code(401);
    die(json_encode(['success' => false, 'message' => 'Incorrect M-PIN']));
}

// Get vendor info
$vendor_stmt = $conn->prepare('SELECT vendor_id, name, email FROM vendors WHERE phone = ?');
$vendor_stmt->bind_param('s', $phone);
$vendor_stmt->execute();
$vendor_result = $vendor_stmt->get_result();

if ($vendor_result->num_rows === 0) {
    http_response_code(401);
    die(json_encode(['success' => false, 'message' => 'Vendor not found']));
}

$vendor = $vendor_result->fetch_assoc();
$vendor_stmt->close();

// Generate JWT token (vendor role)
$token = generateJWT([
    'phone_number' => $phone,
    'vendor_id' => $vendor['vendor_id'],
    'type' => 'vendor_auth',
    'role' => 'vendor',
], 86400);

http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'M-PIN verified',
    'token' => $token,
    'vendor_id' => $vendor['vendor_id'],
    'name' => $vendor['name'],
    'email' => $vendor['email']
]);

$conn->close();
?>
