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

    if (!isset($data['request_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: request_id']);
        exit;
    }

    $requestId = $data['request_id'];

    // Get request details
    $reqStmt = $pdo->prepare("
        SELECT sr.customer_id, sr.assigned_vendor_id, sc.name as service_name
        FROM service_requests sr
        JOIN service_categories sc ON sr.service_category_id = sc.id
        WHERE sr.id = ?
    ");
    $reqStmt->execute([$requestId]);
    $request = $reqStmt->fetch(PDO::FETCH_ASSOC);

    if (!$request) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Request not found']);
        exit;
    }

    // Notify customer of completion
    $custResponse = sendNotification($pdo, 'customer', $request['customer_id'],
        'Service Completed ✓',
        'Your ' . $request['service_name'] . ' service has been completed. Rate your experience!',
        ['type' => 'job_completed', 'request_id' => $requestId]
    );

    // Notify vendor of completion
    $vendorResponse = sendNotification($pdo, 'vendor', $request['assigned_vendor_id'],
        'Job Completed ✓',
        'Job #' . $requestId . ' has been marked as completed. Payment will be processed shortly.',
        ['type' => 'job_completed', 'job_id' => $requestId]
    );

    echo json_encode([
        'success' => true,
        'customer_notified' => $custResponse,
        'vendor_notified' => $vendorResponse,
        'message' => 'Completion notifications sent',
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
