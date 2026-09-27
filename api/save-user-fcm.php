<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    require 'config.php';

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['phone']) || !isset($data['fcm_token'])) {
        throw new Exception('Missing phone or fcm_token');
    }

    $phone = $data['phone'];
    $name = $data['name'] ?? '';
    $fcmToken = $data['fcm_token'];

    // Insert or update user with FCM token
    $stmt = $pdo->prepare("
        INSERT INTO users (phone, name, fcm_token)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
        fcm_token = VALUES(fcm_token),
        name = IF(name = '' OR name IS NULL, VALUES(name), name)
    ");

    $stmt->execute([$phone, $name, $fcmToken]);

    echo json_encode([
        'success' => true,
        'message' => 'FCM token saved',
        'phone' => $phone
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
