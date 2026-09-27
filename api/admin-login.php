<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'rate-limiter.php';
require_once 'jwt-auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Method not allowed']));
}

$data = json_decode(file_get_contents('php://input'), true);

if (empty($data['username']) || empty($data['password'])) {
    http_response_code(400);
    die(json_encode(['success' => false, 'message' => 'username and password are required']));
}

$username = trim($data['username']);
$password = (string) $data['password'];

// Max 5 login attempts per 15 minutes per username - admin accounts are a
// much higher-value target than a customer OTP, so this is deliberately
// stricter than the customer/vendor login rate limits.
checkRateLimit('admin_login_' . strtolower($username), 5, 900);

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$stmt = $conn->prepare("SELECT id, username, password_hash, role, is_active FROM admin_users WHERE username = ? LIMIT 1");
$stmt->bind_param('s', $username);
$stmt->execute();
$admin = $stmt->get_result()->fetch_assoc();
$stmt->close();
$conn->close();

if (!$admin || !$admin['is_active'] || !password_verify($password, $admin['password_hash'])) {
    http_response_code(401);
    die(json_encode(['success' => false, 'message' => 'Invalid username or password']));
}

$token = generateJWT([
    'admin_id' => (int) $admin['id'],
    'username' => $admin['username'],
    'role' => $admin['role'],
]);

http_response_code(200);
echo json_encode([
    'success' => true,
    'token' => $token,
    'token_type' => 'Bearer',
    'expires_in' => 86400,
    'role' => $admin['role'],
    'username' => $admin['username'],
]);
?>
