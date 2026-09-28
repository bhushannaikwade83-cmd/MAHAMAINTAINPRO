<?php
/**
 * Shared FCM push-sending helper - extracted from the logic already
 * working in send-sos-fcm.php (the only endpoint that previously sent a
 * real push) so other events (booking confirmed, payment successful,
 * complaint updates, etc.) can trigger a push the same way instead of
 * only writing a silent row into the in-app `notifications` table.
 */

/**
 * Self-heals the `users` (FCM) table. A table of this generic name may
 * already exist on the server from before this feature was added (e.g. an
 * older login system) with a totally different schema - `CREATE TABLE IF
 * NOT EXISTS` is then a no-op and `phone`/`fcm_token` never get added,
 * which made prepare() return false and crash every caller (create-order,
 * verify-payment, ...) with an uncaught fatal error instead of just
 * skipping the push. Same pattern/fix as ensure-orders-schema.php.
 */
function ensureUsersFcmSchema(mysqli $conn): void {
    $conn->query("CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone VARCHAR(20) UNIQUE NOT NULL,
        name VARCHAR(255),
        fcm_token VARCHAR(500),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )");

    $existing = [];
    $result = $conn->query("SHOW COLUMNS FROM users");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $existing[$row['Field']] = true;
        }
    }

    $expectedColumns = [
        'phone' => 'VARCHAR(20) NULL',
        'name' => 'VARCHAR(255) NULL',
        'fcm_token' => 'VARCHAR(500) NULL',
    ];
    foreach ($expectedColumns as $column => $definition) {
        if (!isset($existing[$column])) {
            $conn->query("ALTER TABLE users ADD COLUMN `$column` $definition");
        }
    }
}

function sendPushToPhone(mysqli $conn, string $phone, string $title, string $body, array $data = []): bool {
    ensureUsersFcmSchema($conn);

    // A push notification is a best-effort side-effect - it must never
    // crash the endpoint that called it (order creation, payment
    // verification, etc.) if the query can't be prepared for any reason.
    $stmt = $conn->prepare("SELECT fcm_token FROM users WHERE phone = ?");
    if (!$stmt) {
        error_log('sendPushToPhone: prepare failed - ' . $conn->error);
        return false;
    }
    $stmt->bind_param('s', $phone);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row || empty($row['fcm_token'])) {
        return false; // No token saved for this phone yet - nothing to push to.
    }

    return sendPushToToken($row['fcm_token'], $title, $body, $data);
}

function sendPushToToken(string $fcmToken, string $title, string $body, array $data = []): bool {
    $keyFilePath = __DIR__ . '/mahamaintainpro-6440d-4cdeb5c2a5eb.json';
    if (!file_exists($keyFilePath)) {
        error_log('Push notification skipped: Firebase key file not found');
        return false;
    }

    $keyData = json_decode(file_get_contents($keyFilePath), true);
    if (!$keyData) {
        error_log('Push notification skipped: invalid Firebase key JSON');
        return false;
    }

    $accessToken = _getFirebaseAccessToken($keyData);
    if (!$accessToken) {
        error_log('Push notification skipped: could not get Firebase access token');
        return false;
    }

    // FCM data payload values must all be strings.
    $stringData = array_map('strval', $data);

    $message = [
        'message' => [
            'token' => $fcmToken,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => $stringData,
        ],
    ];

    $projectId = 'mahamaintainpro-6440d';
    $ch = curl_init("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send");
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json',
        ],
        CURLOPT_POSTFIELDS => json_encode($message),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200) {
        error_log('Push notification failed: ' . $response);
        return false;
    }
    return true;
}

function _getFirebaseAccessToken(array $keyData): ?string {
    $now = time();
    $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
    $payload = json_encode([
        'iss' => $keyData['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $now + 3600,
        'iat' => $now,
    ]);

    $base64Header = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
    $base64Payload = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');
    $signature = '';
    openssl_sign($base64Header . '.' . $base64Payload, $signature, $keyData['private_key'], 'SHA256');
    $jwt = $base64Header . '.' . $base64Payload . '.' . rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

    $ch = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
    ]);
    $response = json_decode(curl_exec($ch), true);
    curl_close($ch);

    return $response['access_token'] ?? null;
}
?>
