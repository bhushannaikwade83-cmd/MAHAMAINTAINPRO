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

// Verify vendor token
$vendor_token = verifyJWTToken();
if (!$vendor_token || $vendor_token['role'] !== 'vendor') {
    http_response_code(401);
    die(json_encode(['success' => false, 'message' => 'Unauthorized']));
}

$data = json_decode(file_get_contents("php://input"), true);
$mpin = trim($data['mpin'] ?? '');
$phone = $vendor_token['phone_number'] ?? null;

if (!$phone || !preg_match('/^[0-9]{4}$/', $mpin)) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'Invalid M-PIN or phone number']));
}

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

// Hash and save MPIN
$mpin_hash = password_hash($mpin, PASSWORD_BCRYPT);

$stmt = $conn->prepare('INSERT INTO vendor_mpin (phone_number, mpin_hash) VALUES (?, ?) ON DUPLICATE KEY UPDATE mpin_hash = ?');
$stmt->bind_param('sss', $phone, $mpin_hash, $mpin_hash);

if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'M-PIN saved successfully'
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to save M-PIN'
    ]);
}

$stmt->close();
$conn->close();
?>
