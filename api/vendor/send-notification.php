<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $pdo = new PDO("mysql:host=localhost;dbname=digitrix_maha_maintain_pro;charset=utf8mb4",
        "digitrix_maha_user", "maha_user@70", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['recipient_type']) || !isset($data['recipient_id']) || !isset($data['title']) || !isset($data['body'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: recipient_type, recipient_id, title, body']);
        exit;
    }

    $recipientType = $data['recipient_type']; // 'customer', 'vendor'
    $recipientId = $data['recipient_id'];
    $title = $data['title'];
    $body = $data['body'];
    $type = $data['type'] ?? 'general'; // 'vendor_assigned', 'vendor_arrived', 'new_job', etc.
    $requestId = $data['request_id'] ?? null;
    $jobId = $data['job_id'] ?? null;

    // Get FCM token based on recipient
    $fcmToken = null;
    if ($recipientType === 'customer') {
        $stmt = $pdo->prepare("SELECT fcm_token FROM customers WHERE id = ?");
        $stmt->execute([$recipientId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        $fcmToken = $result['fcm_token'] ?? null;
    } elseif ($recipientType === 'vendor') {
        $stmt = $pdo->prepare("SELECT fcm_token FROM vendors WHERE id = ?");
        $stmt->execute([$recipientId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        $fcmToken = $result['fcm_token'] ?? null;
    }

    if (!$fcmToken) {
        echo json_encode(['success' => true, 'message' => 'No FCM token found', 'sent' => false]);
        exit;
    }

    // Send FCM notification
    $fcmResponse = sendFCMNotification($fcmToken, $title, $body, [
        'type' => $type,
        'request_id' => $requestId,
        'job_id' => $jobId,
    ]);

    echo json_encode([
        'success' => true,
        'sent' => $fcmResponse,
        'recipient' => $recipientType,
        'recipient_id' => $recipientId,
        'type' => $type,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

function sendFCMNotification($token, $title, $body, $data) {
    $serverKey = getenv('FCM_SERVER_KEY') ?: 'YOUR_FCM_SERVER_KEY';

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: key=' . $serverKey,
    ]);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
        'to' => $token,
        'notification' => [
            'title' => $title,
            'body' => $body,
            'sound' => 'default',
        ],
        'data' => $data,
        'priority' => 'high',
    ]));

    $response = curl_exec($ch);
    curl_close($ch);

    if ($response === false) {
        return false;
    }

    $result = json_decode($response, true);
    return isset($result['success']) && $result['success'] > 0;
}
?>
