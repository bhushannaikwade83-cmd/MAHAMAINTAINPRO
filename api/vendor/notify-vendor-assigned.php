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

    if (!isset($data['request_id']) || !isset($data['vendor_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: request_id, vendor_id']);
        exit;
    }

    $requestId = $data['request_id'];
    $vendorId = $data['vendor_id'];

    // Get request and vendor details
    $reqStmt = $pdo->prepare("SELECT customer_id, service_category_id FROM service_requests WHERE id = ?");
    $reqStmt->execute([$requestId]);
    $request = $reqStmt->fetch(PDO::FETCH_ASSOC);

    if (!$request) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Request not found']);
        exit;
    }

    $vendorStmt = $pdo->prepare("SELECT name FROM vendors WHERE id = ?");
    $vendorStmt->execute([$vendorId]);
    $vendor = $vendorStmt->fetch(PDO::FETCH_ASSOC);

    $catStmt = $pdo->prepare("SELECT name FROM service_categories WHERE id = ?");
    $catStmt->execute([$request['service_category_id']]);
    $category = $catStmt->fetch(PDO::FETCH_ASSOC);

    // Send notification to customer
    $title = 'Vendor Assigned';
    $body = $vendor['name'] . ' will arrive in 15-20 minutes';

    $notifResponse = sendNotification($pdo, 'customer', $request['customer_id'], $title, $body, [
        'type' => 'vendor_assigned',
        'request_id' => $requestId,
        'vendor_name' => $vendor['name'],
        'service' => $category['name'],
    ]);

    echo json_encode([
        'success' => true,
        'notification_sent' => $notifResponse,
        'message' => 'Customer notified of vendor assignment',
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
