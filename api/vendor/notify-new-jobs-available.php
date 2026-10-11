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

    if (!isset($data['vendor_ids']) || !is_array($data['vendor_ids'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: vendor_ids (array)']);
        exit;
    }

    $vendorIds = $data['vendor_ids'];
    $jobCount = count($vendorIds);
    $serviceCategory = $data['service_category'] ?? 'Service';
    $requestId = $data['request_id'] ?? null;

    $notificationsSent = 0;
    $notificationsFailed = 0;

    // Send notification to each vendor
    foreach ($vendorIds as $vendorId) {
        $title = 'New ' . $serviceCategory . ' Job Available!';
        $body = 'Tap to view and accept this job';

        $response = sendNotification($pdo, 'vendor', $vendorId, $title, $body, [
            'type' => 'new_instant_job',
            'request_id' => $requestId,
            'service' => $serviceCategory,
        ]);

        if ($response) {
            $notificationsSent++;
        } else {
            $notificationsFailed++;
        }
    }

    echo json_encode([
        'success' => true,
        'total_vendors' => count($vendorIds),
        'notifications_sent' => $notificationsSent,
        'notifications_failed' => $notificationsFailed,
        'message' => 'Job availability notifications sent to nearby vendors',
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

function sendNotification($pdo, $type, $recipientId, $title, $body, $customData) {
    try {
        $response = file_get_contents('https://digitrixmedia.com/mahamaintainpro/api/vendor/send-notification.php', false, stream_context_create([
            'http' => [
                'method' => 'POST',
                'header' => 'Content-Type: application/json',
                'content' => json_encode([
                    'recipient_type' => $type,
                    'recipient_id' => $recipientId,
                    'title' => $title,
                    'body' => $body,
                    ...$customData,
                ]),
                'timeout' => 5,
            ],
        ]));
        $result = json_decode($response, true);
        return $result['sent'] ?? false;
    } catch (Exception $e) {
        return false;
    }
}
?>
