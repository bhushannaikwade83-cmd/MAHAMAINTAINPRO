<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    require 'config.php';

    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['user_phone']) || !isset($data['contacts'])) {
        throw new Exception('Missing user_phone or contacts');
    }

    $userPhone = $data['user_phone'];
    $userName = $data['user_name'] ?? 'User';
    $location = $data['location'] ?? 'Unknown location';
    $contacts = $data['contacts'] ?? [];
    $fcmTokens = $data['fcm_tokens'] ?? []; // Array of emergency contact FCM tokens
    $userFcmToken = $data['user_fcm_token'] ?? null;

    // Save SOS alert to database with all details
    $stmt = $pdo->prepare("INSERT INTO sos_alerts (user_phone, user_name, user_fcm_token, location, contacts, emergency_fcm_tokens, status)
                          VALUES (?, ?, ?, ?, ?, ?, 'active')");
    $stmt->execute([
        $userPhone,
        $userName,
        $userFcmToken,
        $location,
        json_encode($contacts),
        json_encode($fcmTokens)
    ]);

    $alertId = $pdo->lastInsertId();

    // Firebase credentials (key file in API folder)
    $projectId = 'mahamaintainpro-6440d';
    $keyFilePath = __DIR__ . '/mahamaintainpro-6440d-4cdeb5c2a5eb.json';

    if (!file_exists($keyFilePath)) {
        throw new Exception('Firebase key file not found');
    }

    $privateKey = file_get_contents($keyFilePath);
    $keyData = json_decode($privateKey, true);

    if (!$keyData) {
        throw new Exception('Invalid Firebase key JSON');
    }

    // Get FCM access token
    $accessToken = getFirebaseAccessToken($keyData);

    // Send notifications to each FCM token
    $sentCount = 0;
    foreach ($fcmTokens as $fcmToken) {
        if (empty($fcmToken)) continue;

        $message = [
            'message' => [
                'token' => $fcmToken,
                'notification' => [
                    'title' => '🚨 EMERGENCY SOS ALERT!',
                    'body' => "{$userName} needs help at {$location}"
                ],
                'data' => [
                    'alert_id' => (string)$alertId,
                    'user_phone' => $userPhone,
                    'user_name' => $userName,
                    'location' => $location
                ]
            ]
        ];

        sendFCMNotification($projectId, $accessToken, $message);
        $sentCount++;
    }

    echo json_encode([
        'success' => true,
        'alert_id' => $alertId,
        'message' => "SOS alert sent to {$sentCount} contacts",
        'contacts_notified' => $sentCount
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

function getFirebaseAccessToken($keyData) {
    $now = time();
    $expiryTime = $now + 3600;

    $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
    $payload = json_encode([
        'iss' => $keyData['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $expiryTime,
        'iat' => $now
    ]);

    $base64Header = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
    $base64Payload = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');
    $signature = '';

    openssl_sign($base64Header . '.' . $base64Payload, $signature, $keyData['private_key'], 'SHA256');
    $base64Signature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

    $jwt = $base64Header . '.' . $base64Payload . '.' . $base64Signature;

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $response = json_decode(curl_exec($ch), true);
    curl_close($ch);

    return $response['access_token'] ?? null;
}

function sendFCMNotification($projectId, $accessToken, $message) {
    $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    curl_exec($ch);
    curl_close($ch);
}
?>
