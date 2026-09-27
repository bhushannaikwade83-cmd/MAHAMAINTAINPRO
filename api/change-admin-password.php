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
require_once 'rate-limiter.php';

// Any authenticated admin can change their OWN password only - never
// someone else's, and never without proving the current one first.
$authToken = requireAdminRole();

$data = json_decode(file_get_contents('php://input'), true);
$currentPassword = (string)($data['current_password'] ?? '');
$newPassword = (string)($data['new_password'] ?? '');

if ($currentPassword === '' || $newPassword === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'current_password and new_password are required']);
    exit;
}

// Same class of endpoint as admin-login.php - a brute-force target for
// whoever already holds a valid session token - rate limit by admin id.
checkRateLimit('change_admin_password_' . $authToken['admin_id'], 5, 900);

// Basic strength requirement: 8+ chars, at least one letter and one digit.
if (strlen($newPassword) < 8 || !preg_match('/[A-Za-z]/', $newPassword) || !preg_match('/[0-9]/', $newPassword)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'New password must be at least 8 characters and include both letters and numbers']);
    exit;
}

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    $stmt = $conn->prepare('SELECT password_hash FROM admin_users WHERE id = ? AND is_active = 1');
    $stmt->bind_param('i', $authToken['admin_id']);
    $stmt->execute();
    $admin = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$admin || !password_verify($currentPassword, $admin['password_hash'])) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Current password is incorrect']);
        exit;
    }

    if (password_verify($newPassword, $admin['password_hash'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'New password must be different from the current one']);
        exit;
    }

    $newHash = password_hash($newPassword, PASSWORD_BCRYPT);
    $update = $conn->prepare('UPDATE admin_users SET password_hash = ?, updated_at = NOW() WHERE id = ?');
    $update->bind_param('si', $newHash, $authToken['admin_id']);
    $update->execute();
    $update->close();

    echo json_encode(['success' => true, 'message' => 'Password changed successfully']);
} catch (Exception $e) {
    http_response_code(500);
    error_log('change-admin-password error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
