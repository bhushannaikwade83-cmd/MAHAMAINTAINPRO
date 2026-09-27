<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'jwt-auth.php';
$token = verifyJWTToken();
$phoneNumber = $token['phone_number'];

$conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

// Create notifications table if not exists
$createTable = "CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    type VARCHAR(50) DEFAULT 'general',
    reference_id VARCHAR(100),
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phone (phone_number)
)";
$conn->query($createTable);

try {
    $stmt = $conn->prepare(
        "SELECT id, title, body, type, reference_id, is_read, created_at
         FROM notifications WHERE phone_number = ? ORDER BY created_at DESC LIMIT 50"
    );
    $stmt->bind_param('s', $phoneNumber);
    $stmt->execute();
    $result = $stmt->get_result();

    $notifications = [];
    $unreadCount = 0;
    while ($row = $result->fetch_assoc()) {
        $row['is_read'] = (bool) $row['is_read'];
        if (!$row['is_read']) {
            $unreadCount++;
        }
        $notifications[] = $row;
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'notifications' => $notifications,
        'unread_count' => $unreadCount,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'An internal error occurred. Please try again.']);
}

$conn->close();
?>
