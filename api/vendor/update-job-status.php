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

    if (!isset($data['request_id']) || !isset($data['status'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Missing: request_id, status']);
        exit;
    }

    $valid_statuses = ['PENDING', 'ASSIGNED', 'EN_ROUTE', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'REJECTED'];
    if (!in_array($data['status'], $valid_statuses)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Invalid status']);
        exit;
    }

    $update_fields = ['status = ?'];
    $params = [$data['status'], $data['request_id']];

    // Update timestamp based on status
    if ($data['status'] === 'ARRIVED') {
        $update_fields[] = 'arrived_at = NOW()';
    } elseif ($data['status'] === 'IN_PROGRESS') {
        $update_fields[] = 'started_at = NOW()';
    } elseif ($data['status'] === 'COMPLETED') {
        $update_fields[] = 'completed_at = NOW()';
    } elseif ($data['status'] === 'CANCELLED') {
        $update_fields[] = 'cancelled_at = NOW()';
    }

    if (isset($data['notes'])) {
        $update_fields[] = 'completion_notes = ?';
        array_splice($params, -1, 0, [$data['notes']]);
    }

    $sql = "UPDATE service_requests SET " . implode(', ', $update_fields) . " WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Request not found']);
        exit;
    }

    echo json_encode([
        'success' => true,
        'request_id' => $data['request_id'],
        'status' => $data['status'],
        'updated_at' => date('Y-m-d H:i:s')
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
