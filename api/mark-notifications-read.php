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
$token = verifyJWTToken();
$phoneNumber = $token['phone_number'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['success' => false, 'message' => 'Method not allowed']));
}

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$data = json_decode(file_get_contents('php://input'), true);
$notificationId = isset($data['id']) ? (int) $data['id'] : null;

try {
    if ($notificationId) {
        // Mark a single notification read - scoped to this user's own phone
        // number so one user can't mark (or even probe the existence of)
        // another user's notification by guessing an id.
        $stmt = $conn->prepare(
            "UPDATE notifications SET is_read = 1 WHERE id = ? AND phone_number = ?"
        );
        $stmt->bind_param('is', $notificationId, $phoneNumber);
        $stmt->execute();
        $stmt->close();
    } else {
        // Mark all as read
        $stmt = $conn->prepare(
            "UPDATE notifications SET is_read = 1 WHERE phone_number = ? AND is_read = 0"
        );
        $stmt->bind_param('s', $phoneNumber);
        $stmt->execute();
        $stmt->close();
    }

    http_response_code(200);
    echo json_encode(['success' => true]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
