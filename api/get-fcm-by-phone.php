<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    require 'config.php';

    $phone = $_GET['phone'] ?? ($_POST['phone'] ?? null);

    if (!$phone) {
        throw new Exception('Missing phone parameter');
    }

    $stmt = $pdo->prepare("SELECT fcm_token, name FROM users WHERE phone = ?");
    $stmt->execute([$phone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode([
            'success' => true,
            'fcm_token' => null,
            'name' => null,
            'message' => 'User not found'
        ]);
        return;
    }

    echo json_encode([
        'success' => true,
        'fcm_token' => (string)$user['fcm_token'],
        'name' => (string)$user['name']
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'An internal error occurred. Please try again.']);
}
?>
