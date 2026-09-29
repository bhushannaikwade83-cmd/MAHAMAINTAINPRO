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
$name = trim($data['name'] ?? '');
$email = trim($data['email'] ?? '');
$phone = $vendor_token['phone_number'] ?? null;

if (!$name || !$phone) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'Name and phone are required']));
}

if ($email && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'Invalid email']));
}

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

// Generate vendor_id
$vendor_id = 'VENDOR_' . strtoupper(uniqid());

// Register vendor
$stmt = $conn->prepare('INSERT INTO vendors (vendor_id, name, phone, email, status) VALUES (?, ?, ?, ?, ?)');
$status = 'active';
$stmt->bind_param('sssss', $vendor_id, $name, $phone, $email, $status);

if ($stmt->execute()) {
    // Update token with correct vendor_id
    $token = generateJWT([
        'phone_number' => $phone,
        'vendor_id' => $vendor_id,
        'type' => 'vendor_auth',
        'role' => 'vendor',
    ], 86400);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Vendor registered successfully',
        'token' => $token,
        'vendor_id' => $vendor_id,
        'name' => $name,
        'email' => $email
    ]);
} else {
    if (strpos($stmt->error, 'Duplicate entry') !== false) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Vendor with this phone already exists']);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to register vendor']);
    }
}

$stmt->close();
$conn->close();
?>
